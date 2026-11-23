# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # SQLite adapter implementing introspection via sqlite_master and PRAGMA statements
    #
    # Tables, indexes and views carry their original CREATE statements from
    # sqlite_master, the only lossless record of SQLite DDL (AUTOINCREMENT,
    # WITHOUT ROWID, STRICT, inline foreign keys, partial/expression indexes).
    class SqliteAdapter < BaseAdapter
      # Persistent PRAGMAs that describe the database file (all default to 0)
      PERSISTENT_PRAGMAS = %w[application_id auto_vacuum user_version].freeze

      # PRAGMA table_xinfo "hidden" values marking generated columns
      GENERATED_COLUMN_KINDS = { 2 => 'VIRTUAL', 3 => 'STORED' }.freeze

      # Characters opening a quoted string or identifier in SQLite SQL
      QUOTE_CHARS = %w[' " `].freeze

      # CREATE VIEW statement; captures the SELECT after an optionally quoted view name
      VIEW_STATEMENT = /\ACREATE\s+(?:TEMP(?:ORARY)?\s+)?VIEW\s+(?:IF\s+NOT\s+EXISTS\s+)?
                        (?:"(?:[^"]|"")+"|`[^`]+`|\[[^\]]+\]|[^\s(]+)\s+AS\s+(.*)\z/imx

      # Introspection methods using sqlite_master and PRAGMA

      # Fetch extensions (PRAGMA settings for SQLite)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of PRAGMA setting hashes with :name, :value, :sql
      # @note SQLite doesn't support extensions like PostgreSQL, but returns important PRAGMA settings
      def fetch_extensions(connection)
        # SQLite doesn't support extensions like PostgreSQL, but we can fetch PRAGMA settings
        # Return them in a format compatible with the extensions section
        fetch_pragma_settings(connection)
      end

      # Fetch PRAGMA settings stored in the database file
      #
      # Only persistent, schema-level PRAGMAs with non-default values are returned.
      # Connection-scoped settings (journal_mode, synchronous, cache_size,
      # foreign_keys, ...) are configured by Rails per connection, are not part
      # of the schema, and would make the dump differ between environments.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of PRAGMA hashes with :name, :value, :sql
      def fetch_pragma_settings(connection)
        PERSISTENT_PRAGMAS.filter_map do |pragma_name|
          value = connection.select_value("PRAGMA #{pragma_name}")
          next if value.to_i.zero?

          { name: pragma_name, value:, sql: "PRAGMA #{pragma_name} = #{value};" }
        end
      end

      # Fetch custom types (not supported in SQLite)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as SQLite doesn't support custom types
      def fetch_custom_types(_connection)
        # SQLite doesn't support custom types
        []
      end

      # Fetch all tables from the database
      #
      # :sql holds the original CREATE TABLE statement from sqlite_master, the
      # only lossless source for AUTOINCREMENT, WITHOUT ROWID, STRICT, generated
      # column expressions, collations and constraint names.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :sql, :columns, :primary_key, :constraints
      def fetch_tables(connection)
        connection.execute(tables_query).map do |row|
          table_info = connection.execute("PRAGMA table_xinfo(#{quote_identifier(row['name'])})").to_a

          {
            name: row['name'],
            schema: 'main',
            sql: row['sql'],
            columns: extract_columns_from_table_info(table_info, row['sql']),
            primary_key: extract_primary_key_from_table_info(table_info),
            constraints: extract_check_constraints(row['sql'])
          }
        end
      end

      # Fetch all explicitly created indexes from the database
      #
      # The definition is the original CREATE INDEX statement, so partial
      # (WHERE) and expression indexes are preserved. Indexes SQLite creates
      # implicitly for PRIMARY KEY/UNIQUE constraints have no SQL and are
      # recreated by their CREATE TABLE.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :table, :name, :columns, :unique, :type, :definition
      def fetch_indexes(connection)
        query = <<~SQL.squish
          SELECT name, tbl_name, sql
          FROM sqlite_master
          WHERE type = 'index'
            AND sql IS NOT NULL
          ORDER BY tbl_name, name
        SQL

        connection.execute(query).map do |row|
          {
            table: row['tbl_name'],
            name: row['name'],
            columns: fetch_index_columns(connection, row['name']),
            unique: row['sql'].match?(/\ACREATE\s+UNIQUE\b/i),
            type: 'BTREE',
            definition: row['sql']
          }
        end
      end

      # Fetch all foreign keys from the database
      #
      # PRAGMA foreign_key_list reports one row per column and numbers keys in
      # reverse declaration order; keys are regrouped (composite keys become a
      # single entry listing their columns) and returned in declaration
      # order so a dump/load cycle keeps the original order.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :columns, :foreign_table, :foreign_columns, :on_update, :on_delete
      def fetch_foreign_keys(connection)
        fetch_table_names(connection).flat_map do |table_name|
          connection.execute("PRAGMA foreign_key_list(#{quote_identifier(table_name)})")
                    .group_by { |row| row['id'] }
                    .sort_by { |id, _rows| -id }
                    .map { |_id, rows| build_foreign_key(table_name, rows.sort_by { |row| row['seq'] }) }
        end
      end

      # Fetch all views from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition, :sql, :updatable
      #   (:definition is the SELECT statement; :sql the original CREATE VIEW statement)
      def fetch_views(connection)
        query = <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'view'
          ORDER BY name
        SQL

        connection.execute(query).map do |row|
          {
            schema: 'main',
            name: row['name'],
            definition: view_select(row['sql']),
            sql: row['sql'],
            updatable: false # SQLite views are read-only unless INSTEAD OF triggers exist
          }
        end
      end

      # Fetch materialized views (not supported in SQLite)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as SQLite doesn't support materialized views
      def fetch_materialized_views(_connection)
        # SQLite doesn't support materialized views
        []
      end

      # Fetch functions (not supported in SQLite)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as SQLite doesn't support stored procedures/functions
      # @note SQLite only supports user-defined functions in C/Ruby, not SQL stored procedures
      def fetch_functions(_connection)
        # SQLite doesn't support stored procedures/functions (only user-defined functions in C/Ruby)
        []
      end

      # Fetch sequences (not supported in SQLite)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as SQLite doesn't support sequences (uses AUTOINCREMENT instead)
      def fetch_sequences(_connection)
        # SQLite doesn't have sequences (uses AUTOINCREMENT)
        []
      end

      # Fetch all triggers from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger hashes with :schema, :name, :table_name, :timing, :event, :definition
      def fetch_triggers(connection)
        query = triggers_query
        connection.execute(query).map { |row| build_trigger_hash(row) }
      end

      # Fetch comments on database objects (not supported in SQLite)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Hash] Empty hash for all object types
      def fetch_comments(_connection)
        {
          tables: {},
          columns: {},
          indexes: {},
          views: {},
          functions: {},
          procedures: {}
        }
      end

      # Capability methods - SQLite feature support

      # Indicates whether SQLite supports extensions
      #
      # @return [Boolean] Always false for SQLite
      def supports_extensions?
        false
      end

      # Indicates whether SQLite supports materialized views
      #
      # @return [Boolean] Always false for SQLite
      def supports_materialized_views?
        false
      end

      # Indicates whether SQLite supports custom types
      #
      # @return [Boolean] Always false for SQLite
      def supports_custom_types?
        false
      end

      # Indicates whether SQLite supports domains
      #
      # @return [Boolean] Always false for SQLite
      def supports_domains?
        false
      end

      # Indicates whether SQLite supports stored procedures/functions
      #
      # @return [Boolean] Always false (no stored procedures/functions in SQLite)
      def supports_functions?
        false # No stored procedures/functions
      end

      # Indicates whether SQLite supports triggers
      #
      # @return [Boolean] Always true for SQLite
      def supports_triggers?
        true
      end

      # Indicates whether SQLite supports sequences
      #
      # @return [Boolean] Always false (uses AUTOINCREMENT instead)
      def supports_sequences?
        false # Uses AUTOINCREMENT instead
      end

      # Indicates whether SQLite supports check constraints
      #
      # @return [Boolean] Always true (SQLite has always supported CHECK constraints)
      def supports_check_constraints?
        true # SQLite has always supported CHECK constraints
      end

      # Version detection

      # Get the current SQLite database version
      #
      # @return [String] Normalized version string (e.g., "3.45.1")
      def database_version
        @database_version ||= begin
          version_string = connection.select_value('SELECT sqlite_version()')
          parse_version(version_string)
        end
      end

      # Parse SQLite version string into normalized format
      #
      # @param version_string [String] Raw version string from SQLite (e.g., "3.45.1")
      # @return [String] Normalized version (e.g., "3.45.1") or "unknown" if parsing fails
      def parse_version(version_string)
        # Example: "3.45.1"
        match = version_string.match(/(\d+\.\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Helper methods for introspection

      # Query for tables, excluding SQLite's own (sqlite_%)
      #
      # schema_migrations and ar_internal_metadata are dumped like on the other
      # adapters: a loaded dump needs schema_migrations for its INSERT, or every
      # migration is pending.
      #
      # @return [String] SQL query returning name and sql
      def tables_query
        <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
          ORDER BY name
        SQL
      end

      # Fetch table names from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<String>] Array of table names
      def fetch_table_names(connection)
        connection.execute(tables_query).pluck('name')
      end

      # Extract columns from PRAGMA table_xinfo rows
      #
      # table_xinfo (unlike table_info) includes generated columns, flagged by
      # hidden = 2 (VIRTUAL) or 3 (STORED). The declared type is kept verbatim
      # (e.g. "varchar(255)") because Rails derives column limits from it.
      #
      # @param table_info [Array<Hash>] Rows from PRAGMA table_xinfo
      # @param sql [String] CREATE TABLE statement (source of generation expressions)
      # @return [Array<Hash>] Array of column hashes
      def extract_columns_from_table_info(table_info, sql)
        table_info.reject { |row| row['hidden'] == 1 }.map do |row|
          {
            name: row['name'],
            type: row['type'],
            nullable: row['notnull'].to_i.zero?,
            default: row['dflt_value'],
            primary_key: row['pk'].to_i.positive?,
            generated: generated_column(sql, row['name'], GENERATED_COLUMN_KINDS[row['hidden']])
          }
        end
      end

      # Generation expression of a generated column, parsed from CREATE TABLE
      #
      # @param sql [String] CREATE TABLE statement
      # @param name [String] Column name
      # @param kind [String, nil] "VIRTUAL", "STORED" or nil for ordinary columns
      # @return [Hash, nil] { expression:, kind: } for generated columns
      def generated_column(sql, name, kind)
        return nil unless kind

        definition = table_elements(sql).find { |element| element_name(element).casecmp?(name) }
        open_index = definition.index(/\bAS\s*\(/i)
        raise Error, "Unable to find expression of generated column #{name} in: #{sql}" unless open_index

        expression = balanced_parenthesized(definition, definition.index('(', open_index))
        { expression: expression[1...-1].strip, kind: }
      end

      # Top-level comma-separated elements (columns and table constraints) of a CREATE TABLE
      #
      # @param sql [String] CREATE TABLE statement
      # @return [Array<String>] Element definitions
      def table_elements(sql)
        body = balanced_parenthesized(sql, sql.index('('))[1...-1]
        elements = [+'']
        scan_sql(body) do |char, depth|
          next elements << +'' if char == ',' && depth&.zero?

          elements.last << char
        end
        elements.map(&:strip)
      end

      # Unquoted leading identifier of a table element
      #
      # @param element [String] Column or constraint definition
      # @return [String] Identifier
      def element_name(element)
        token = element[/\A(?:"(?:[^"]|"")+"|`[^`]+`|\[[^\]]+\]|[^\s]+)/]
        token.match?(/\A["`\[]/) ? token[1...-1].gsub('""', '"') : token
      end

      # Extract primary key columns from PRAGMA table_xinfo rows
      #
      # @param table_info [Array<Hash>] Rows from PRAGMA table_xinfo
      # @return [Array<String>] Primary key column names in key order (pk is the 1-based position)
      def extract_primary_key_from_table_info(table_info)
        table_info
          .select { |row| row['pk'].to_i.positive? }
          .sort_by { |row| row['pk'] }
          .pluck('name')
      end

      # Extract named CHECK constraints from a CREATE TABLE statement
      #
      # @param sql [String, nil] CREATE TABLE statement
      # @return [Array<Hash>] Constraint hashes whose :definition is "CHECK (...)"
      def extract_check_constraints(sql)
        return [] unless sql

        constraints = []
        sql.scan(/CONSTRAINT\s+("(?:[^"]|"")+"|`[^`]+`|\[[^\]]+\]|\w+)\s+CHECK\s*\(/i) do |(name)|
          expression = balanced_parenthesized(sql, Regexp.last_match.end(0) - 1)
          constraints << { name:, definition: "CHECK #{expression}", type: :check }
        end
        constraints
      end

      # Return the parenthesized expression starting at +open_index+, honoring
      # nesting and quoted strings/identifiers
      #
      # @param sql [String] SQL text
      # @param open_index [Integer] Index of the opening parenthesis
      # @return [String] Text from the opening to the matching closing parenthesis
      # @raise [Error] If the parenthesis is never closed
      def balanced_parenthesized(sql, open_index)
        scan_sql(sql[open_index..]).with_index do |(char, depth), offset|
          return sql[open_index, offset + 1] if char == ')' && depth&.zero?
        end
        raise Error, "Unbalanced parentheses in: #{sql}"
      end

      # Yield each character with the parenthesis depth outside quoted text
      # (depth after an opening and before a closing parenthesis are the same
      # level, so a ")" yielded with depth 0 closes the outermost group)
      #
      # @param sql [String] SQL text
      # @yieldparam char [String] Character
      # @yieldparam depth [Integer, nil] Parenthesis depth, nil inside quotes
      # @return [Enumerator] When no block is given
      def scan_sql(sql)
        return enum_for(:scan_sql, sql) unless block_given?

        depth = 0
        quote = nil
        sql.each_char do |char|
          if quote
            quote = nil if char == quote
            yield char, nil
          elsif QUOTE_CHARS.include?(char)
            quote = char
            yield char, nil
          else
            depth -= 1 if char == ')'
            yield char, depth
            depth += 1 if char == '('
          end
        end
      end

      # Extract the SELECT statement from a CREATE VIEW statement
      #
      # @param sql [String] CREATE VIEW statement from sqlite_master
      # @return [String] View query
      # @raise [Error] If the statement cannot be parsed
      def view_select(sql)
        select = sql[VIEW_STATEMENT, 1]
        raise Error, "Unable to parse view definition: #{sql}" unless select

        select
      end

      # Build a foreign key hash from PRAGMA foreign_key_list rows of one key
      #
      # @param table_name [String] Referencing table
      # @param rows [Array<Hash>] Rows of one foreign key, in column order
      # @return [Hash] Foreign key hash
      def build_foreign_key(table_name, rows)
        columns = rows.pluck('from')
        first = rows.first

        {
          table: table_name,
          name: "fk_#{table_name}_#{first['table']}_#{columns.join('_')}", # SQLite does not expose FK names
          columns:,
          foreign_table: first['table'],
          foreign_columns: rows.pluck('to'),
          on_update: first['on_update'],
          on_delete: first['on_delete']
        }
      end

      # Quote identifier (table/column name) with double quotes
      #
      # @param name [String] Identifier to quote
      # @return [String] Quoted identifier (e.g., "table_name")
      def quote_identifier(name)
        "\"#{name.gsub('"', '""')}\""
      end

      # Fetch columns for a specific index (expression key parts are omitted)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param index_name [String] Index name
      # @return [Array<String>] Array of column names
      def fetch_index_columns(connection, index_name)
        connection.execute("PRAGMA index_info(#{quote_identifier(index_name)})").filter_map { |row| row['name'] }
      end

      # SQL query for fetching triggers
      #
      # @return [String] SQL query string
      def triggers_query
        <<~SQL.squish
          SELECT name, tbl_name, sql
          FROM sqlite_master
          WHERE type = 'trigger'
          ORDER BY tbl_name, name
        SQL
      end

      # Build trigger hash from query row
      #
      # @param row [Hash] Row from triggers query
      # @return [Hash] Trigger hash with parsed timing and event
      def build_trigger_hash(row)
        sql = row['sql'] || row[2] || ''

        {
          schema: 'main',
          name: row['name'] || row[0],
          table_name: row['tbl_name'] || row[1],
          timing: parse_trigger_timing(sql),
          event: parse_trigger_event(sql),
          definition: sql
        }
      end

      # Parse trigger timing from SQL
      #
      # @param sql [String] Trigger SQL definition
      # @return [String] Timing ('BEFORE', 'AFTER', or 'INSTEAD OF')
      def parse_trigger_timing(sql)
        timing_match = sql.match(/\b(BEFORE|AFTER|INSTEAD OF)\b/i)
        timing_match ? timing_match.captures.first.upcase : 'AFTER'
      end

      # Parse trigger event from SQL
      #
      # @param sql [String] Trigger SQL definition
      # @return [String] Event ('INSERT', 'UPDATE', or 'DELETE')
      def parse_trigger_event(sql)
        event_match = sql.match(/\b(INSERT|UPDATE|DELETE)\b/i)
        event_match ? event_match.captures.first.upcase : 'INSERT'
      end
    end
  end
end
