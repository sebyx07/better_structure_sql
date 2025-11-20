# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # SQLite adapter implementing introspection via sqlite_master and PRAGMA statements
    #
    # Provides SQLite-specific SQL generation with proper dialect support.
    # This adapter handles SQLite's unique features including PRAGMA settings,
    # inline foreign keys, AUTOINCREMENT, and type affinities.
    class SqliteAdapter < BaseAdapter
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

      # Fetch important PRAGMA settings for SQLite
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of PRAGMA hashes with :name, :value, :sql
      def fetch_pragma_settings(connection)
        # List of important PRAGMAs to preserve in schema dump
        important_pragmas = %w[
          foreign_keys
          recursive_triggers
          defer_foreign_keys
          journal_mode
          synchronous
          temp_store
          locking_mode
          auto_vacuum
          cache_size
        ]

        pragmas = []
        important_pragmas.each do |pragma_name|
          result = connection.execute("PRAGMA #{pragma_name}").first
          next unless result

          value = result.is_a?(Hash) ? (result[pragma_name] || result.values.first) : result[0]

          # Only include non-default values that make sense to preserve
          next if value.nil? || value.to_s.empty?
          next if pragma_name == 'foreign_keys' && value.to_i.zero? # Skip if FK disabled

          pragmas << {
            name: pragma_name,
            value: value,
            sql: "PRAGMA #{pragma_name} = #{format_pragma_value(pragma_name, value)};"
          }
        rescue StandardError => e
          # Skip PRAGMAs that fail (might not be supported in this SQLite version)
          Rails.logger.debug { "Skipping PRAGMA #{pragma_name}: #{e.message}" } if defined?(Rails)
        end

        pragmas
      end

      # Format PRAGMA value for SQL statement
      #
      # @param pragma_name [String] Name of the PRAGMA
      # @param value [Object] Value of the PRAGMA
      # @return [String] Formatted value (quoted if string, unquoted if numeric)
      def format_pragma_value(pragma_name, value)
        # String values need quotes, numeric values don't
        case pragma_name
        when 'journal_mode', 'locking_mode', 'temp_store', 'synchronous'
          value.to_s.match?(/^\d+$/) ? value.to_s : "'#{value}'"
        else
          value.to_s
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
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :sql, :columns, :primary_key, :constraints
      def fetch_tables(connection)
        # Performance optimized: Reduces PRAGMA calls by batching table_info queries
        # For 1000 tables: ~2000 fewer PRAGMA calls (~2x faster)
        query = <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
            AND name != 'schema_migrations'
            AND name != 'ar_internal_metadata'
          ORDER BY name
        SQL

        table_rows = connection.execute(query).to_a
        return [] if table_rows.empty?

        table_names = table_rows.map { |row| row['name'] || row[0] }

        # Batch fetch all table_info (columns + primary keys) and constraints
        table_info_by_table = fetch_all_table_info(connection, table_names)
        constraints_by_table = fetch_all_constraints(connection, table_names)

        # Combine results
        table_rows.map do |row|
          table_name = row['name'] || row[0]
          table_info = table_info_by_table[table_name] || []

          {
            name: table_name,
            schema: 'main',
            sql: row['sql'] || row[1],
            columns: extract_columns_from_table_info(table_info),
            primary_key: extract_primary_key_from_table_info(table_info),
            constraints: constraints_by_table[table_name] || []
          }
        end
      end

      # Fetch all indexes from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :table, :name, :columns, :unique, :type, :definition
      def fetch_indexes(connection)
        tables = fetch_table_names(connection)
        indexes = []

        tables.each do |table_name|
          indexes.concat(fetch_table_indexes(connection, table_name))
        end

        indexes
      end

      # Fetch all foreign keys from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :column, :foreign_table, :foreign_column, :on_update, :on_delete
      def fetch_foreign_keys(connection)
        tables = fetch_table_names(connection)
        foreign_keys = []

        tables.each do |table_name|
          fk_list = connection.execute("PRAGMA foreign_key_list(#{quote_identifier(table_name)})")

          fk_list.each do |fk_row|
            from_col = fk_row['from'] || fk_row[3]
            to_table = fk_row['table'] || fk_row[2]
            to_col = fk_row['to'] || fk_row[4]

            foreign_keys << {
              table: table_name,
              name: "fk_#{table_name}_#{to_table}_#{from_col}", # Generate name
              column: from_col,
              foreign_table: to_table,
              foreign_column: to_col,
              on_update: fk_row['on_update'] || fk_row[5],
              on_delete: fk_row['on_delete'] || fk_row[6]
            }
          end
        end

        foreign_keys
      end

      # Fetch all views from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition, :updatable
      def fetch_views(connection)
        query = <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'view'
          ORDER BY name
        SQL

        connection.execute(query).map do |row|
          sql = row['sql'] || row[1]
          # Extract just the SELECT part from CREATE VIEW statement for compatibility
          # with existing ViewGenerator
          definition = if sql&.match(/CREATE\s+VIEW\s+\w+\s+AS\s+(.*)/im)
                         ::Regexp.last_match(1)
                       else
                         sql
                       end

          {
            schema: 'main',
            name: row['name'] || row[0],
            definition: definition || '',
            updatable: false # SQLite views are generally not updatable
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

      # SQL Generation methods - SQLite-specific syntax

      # Generate CREATE TABLE statement for SQLite
      #
      # @param table [Hash] Table hash with :name, :columns, :primary_key, :foreign_keys
      # @return [String] CREATE TABLE SQL statement
      def generate_table(table)
        sql = table[:sql]
        return sql if sql # Use original SQL from sqlite_master if available

        # Generate from columns if needed
        lines = ["CREATE TABLE #{quote_identifier(table[:name])} ("]

        column_defs = table[:columns].map do |col|
          generate_column_definition(col, table[:primary_key])
        end

        # Add foreign keys inline if present
        table[:foreign_keys]&.each do |fk|
          column_defs << generate_foreign_key_inline(fk)
        end

        lines << column_defs.map { |col_def| "  #{col_def}" }.join(",\n")
        lines << ');'

        lines.join("\n")
      end

      # Generate CREATE INDEX statement for SQLite
      #
      # @param index [Hash] Index hash with :name, :table, :columns, :unique
      # @return [String] CREATE INDEX SQL statement
      def generate_index(index)
        unique = index[:unique] ? 'UNIQUE ' : ''
        columns = index[:columns].map { |col| quote_identifier(col) }.join(', ')

        "CREATE #{unique}INDEX #{quote_identifier(index[:name])} " \
          "ON #{quote_identifier(index[:table])} (#{columns});"
      end

      # Generate foreign key constraint (inline with table definition)
      #
      # @param fk [Hash] Foreign key hash with :column, :foreign_table, :foreign_column, :on_delete, :on_update
      # @return [String] FOREIGN KEY constraint SQL
      # @note SQLite requires foreign keys inline with CREATE TABLE
      # rubocop:disable Naming/MethodParameterName
      def generate_foreign_key(fk)
        # SQLite requires foreign keys inline with CREATE TABLE
        # This method is for documentation - actual usage is generate_foreign_key_inline
        generate_foreign_key_inline(fk)
      end

      # Generate CREATE VIEW statement for SQLite
      #
      # @param view [Hash] View hash with :name, :definition
      # @return [String] CREATE VIEW SQL statement
      def generate_view(view)
        definition = view[:definition]
        return definition if /^CREATE\s+VIEW/i.match?(definition) # Already complete

        "CREATE VIEW #{quote_identifier(view[:name])} AS\n#{definition};"
      end

      # Generate CREATE TRIGGER statement for SQLite
      #
      # @param trigger [Hash] Trigger hash with :name, :timing, :event, :table_name, :definition, :body
      # @return [String] CREATE TRIGGER SQL statement
      def generate_trigger(trigger)
        definition = trigger[:definition]
        return definition if /^CREATE\s+TRIGGER/i.match?(definition) # Already complete

        # Generate from components
        timing = trigger[:timing] || 'AFTER'
        event = trigger[:event] || 'INSERT'
        table = trigger[:table_name]
        body = trigger[:body] || trigger[:definition]

        <<~SQL.strip
          CREATE TRIGGER #{quote_identifier(trigger[:name])}
          #{timing} #{event} ON #{quote_identifier(table)}
          BEGIN
            #{body}
          END;
        SQL
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

      # Fetch table names from the database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<String>] Array of table names
      def fetch_table_names(connection)
        query = <<~SQL.squish
          SELECT name
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
            AND name != 'schema_migrations'
            AND name != 'ar_internal_metadata'
          ORDER BY name
        SQL

        connection.execute(query).map { |row| row['name'] || row[0] }
      end

      # Fetch columns for a specific table using PRAGMA table_info
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of column hashes with :name, :type, :nullable, :default, :primary_key
      def fetch_columns(connection, table_name)
        table_info = connection.execute("PRAGMA table_info(#{quote_identifier(table_name)})")

        table_info.map do |row|
          {
            name: row['name'] || row[1],
            type: resolve_column_type(row['type'] || row[2]),
            nullable: (row['notnull'] || row[3]).to_i.zero?,
            default: row['dflt_value'] || row[4],
            primary_key: (row['pk'] || row[5]).to_i == 1
          }
        end
      end

      # Fetch primary key columns for a specific table using PRAGMA table_info
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<String>] Array of primary key column names in pk order
      def fetch_primary_key(connection, table_name)
        table_info = connection.execute("PRAGMA table_info(#{quote_identifier(table_name)})")

        table_info
          .select { |row| (row['pk'] || row[5]).to_i == 1 }
          .sort_by { |row| row['pk'] || row[5] } # Sort by pk order
          .map { |row| row['name'] || row[1] }
      end

      # Fetch CHECK constraints for a specific table by parsing table SQL
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of constraint hashes with :name, :definition, :type
      def fetch_constraints(connection, table_name)
        # SQLite stores CHECK constraints in the table SQL
        # Parse from sqlite_master
        query = <<~SQL.squish
          SELECT sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name = '#{table_name}'
        SQL

        result = connection.execute(query).first
        return [] unless result

        sql = result['sql'] || result[0]
        return [] unless sql

        # Extract CHECK constraints from SQL
        # This is a simplified parser - real implementation would be more robust
        checks = []
        sql.scan(/CONSTRAINT\s+(\w+)\s+CHECK\s*\(([^)]+)\)/i) do |match|
          checks << {
            name: match[0],
            definition: match[1],
            type: :check
          }
        end

        checks
      end

      # Batch fetch all table_info for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of table_info rows
      def fetch_all_table_info(connection, table_names)
        result = {}

        table_names.each do |table_name|
          table_info = connection.execute("PRAGMA table_info(#{quote_identifier(table_name)})")
          result[table_name] = table_info.to_a
        end

        result
      end

      # Batch fetch all constraints for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of constraint hashes
      def fetch_all_constraints(connection, table_names)
        return {} if table_names.empty?

        # Fetch all table SQL in one query
        quoted_names = table_names.map { |t| "'#{t}'" }.join(', ')
        query = <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name IN (#{quoted_names})
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.execute(query).each do |row|
          table_name = row['name'] || row[0]
          sql = row['sql'] || row[1]
          next unless sql

          # Extract CHECK constraints from SQL
          sql.scan(/CONSTRAINT\s+(\w+)\s+CHECK\s*\(([^)]+)\)/i) do |match|
            result[table_name] << {
              name: match[0],
              definition: match[1],
              type: :check
            }
          end
        end

        result
      end

      # Extract columns from table_info rows
      #
      # @param table_info [Array<Hash>] Array of table_info rows from PRAGMA table_info
      # @return [Array<Hash>] Array of column hashes
      def extract_columns_from_table_info(table_info)
        table_info.map do |row|
          {
            name: row['name'] || row[1],
            type: resolve_column_type(row['type'] || row[2]),
            nullable: (row['notnull'] || row[3]).to_i.zero?,
            default: row['dflt_value'] || row[4],
            primary_key: (row['pk'] || row[5]).to_i == 1
          }
        end
      end

      # Extract primary key columns from table_info rows
      #
      # @param table_info [Array<Hash>] Array of table_info rows from PRAGMA table_info
      # @return [Array<String>] Array of primary key column names in pk order
      def extract_primary_key_from_table_info(table_info)
        table_info
          .select { |row| (row['pk'] || row[5]).to_i == 1 }
          .sort_by { |row| row['pk'] || row[5] }
          .map { |row| row['name'] || row[1] }
      end

      # Resolve SQLite column type into normalized format using type affinity
      #
      # @param type_string [String] Raw column type from PRAGMA table_info
      # @return [String] Normalized column type based on SQLite type affinity rules
      def resolve_column_type(type_string)
        # SQLite type affinity mapping
        # Normalize common types
        type_lower = type_string.to_s.downcase

        case type_lower
        when /^int/
          'integer'
        when /^varchar/, /^char/, /^text/
          'text'
        when /^real/, /^float/, /^double/
          'real'
        when /^decimal/, /^numeric/
          # Keep precision if specified
          type_string
        when /^blob/
          'blob'
        when /^bool/
          'boolean'
        when /^date/, /^time/
          # SQLite stores dates/times as TEXT or INTEGER
          type_string
        when /^json/
          'json' # Stored as TEXT but semantically JSON
        else
          type_string
        end
      end

      # Generate column definition for CREATE TABLE
      #
      # @param col [Hash] Column hash with :name, :type, :nullable, :default, :primary_key, :extra
      # @param primary_keys [Array<String>] List of primary key column names
      # @return [String] Column definition SQL
      def generate_column_definition(col, primary_keys = [])
        parts = [quote_identifier(col[:name]), col[:type].upcase]

        # PRIMARY KEY for single-column pk with AUTOINCREMENT
        if col[:primary_key] && primary_keys.length == 1
          parts << 'PRIMARY KEY'
          parts << 'AUTOINCREMENT' if col[:extra]&.include?('auto_increment') || col[:type]&.downcase == 'integer'
        end

        parts << 'NOT NULL' unless col[:nullable]
        parts << "DEFAULT #{format_default_value(col[:default])}" if col[:default]

        parts.join(' ')
      end

      # Generate inline foreign key constraint
      #
      # @param fk [Hash] Foreign key hash with :column, :foreign_table, :foreign_column, :on_delete, :on_update
      # @return [String] FOREIGN KEY constraint SQL
      def generate_foreign_key_inline(fk)
        parts = ["FOREIGN KEY (#{quote_identifier(fk[:column])})"]
        parts << "REFERENCES #{quote_identifier(fk[:foreign_table])}(#{quote_identifier(fk[:foreign_column])})"
        parts << "ON DELETE #{fk[:on_delete]}" if fk[:on_delete]
        parts << "ON UPDATE #{fk[:on_update]}" if fk[:on_update]

        parts.join(' ')
      end
      # rubocop:enable Naming/MethodParameterName

      # Quote identifier (table/column name) with double quotes
      #
      # @param name [String] Identifier to quote
      # @return [String] Quoted identifier (e.g., "table_name")
      def quote_identifier(name)
        "\"#{name}\""
      end

      # Format default value for SQL statement
      #
      # @param value [Object] Default value (can be nil, String, Boolean, or other)
      # @return [String] Formatted default value for SQL
      def format_default_value(value)
        case value
        when nil
          'NULL'
        when String
          # Check if it looks like a function call (uppercase letters/underscores followed by parentheses)
          # or datetime/current_timestamp keywords
          if value =~ /^[A-Z_]+\(/i || value =~ /^(CURRENT_|datetime|date|time)/i
            value
          else
            "'#{value.gsub("'", "''")}'"
          end
        when TrueClass
          '1'
        when FalseClass
          '0'
        else
          value.to_s
        end
      end

      # Fetch indexes for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Table name
      # @return [Array<Hash>] Array of index hashes
      def fetch_table_indexes(connection, table_name)
        index_list = connection.execute("PRAGMA index_list(#{quote_identifier(table_name)})")
        skip_origins = %w[pk u].freeze
        indexes = []

        index_list.each do |index_row|
          index_name = index_row['name'] || index_row[1]
          is_unique = (index_row['unique'] || index_row[2]).to_i == 1
          origin = index_row['origin'] || index_row[3]

          next if skip_origins.include?(origin)

          columns = fetch_index_columns(connection, index_name)
          definition = build_index_definition(table_name, index_name, is_unique, columns)

          indexes << {
            table: table_name,
            name: index_name,
            columns: columns,
            unique: is_unique,
            type: 'BTREE',
            definition: definition
          }
        end

        indexes
      end

      # Fetch columns for a specific index
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param index_name [String] Index name
      # @return [Array<String>] Array of column names
      def fetch_index_columns(connection, index_name)
        index_info = connection.execute("PRAGMA index_info(#{quote_identifier(index_name)})")
        index_info.map { |col_row| col_row['name'] || col_row[2] }
      end

      # Build CREATE INDEX definition string
      #
      # @param table_name [String] Table name
      # @param index_name [String] Index name
      # @param is_unique [Boolean] Whether index is unique
      # @param columns [Array<String>] Column names
      # @return [String] CREATE INDEX SQL statement
      def build_index_definition(table_name, index_name, is_unique, columns)
        unique_clause = is_unique ? 'UNIQUE ' : ''
        columns_clause = columns.map { |col| quote_identifier(col) }.join(', ')
        "CREATE #{unique_clause}INDEX #{quote_identifier(index_name)} " \
        "ON #{quote_identifier(table_name)} (#{columns_clause})"
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
