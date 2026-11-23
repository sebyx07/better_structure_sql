# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # MySQL adapter implementing introspection via information_schema and MySQL system tables.
    #
    # Works with both the mysql2 and trilogy drivers (queries go through
    # ActiveRecord's select_rows, never driver-specific result objects) and
    # with MariaDB servers.
    #
    # Column defaults, CHECK constraint definitions and index definitions are
    # returned as ready-to-use SQL fragments, matching the PostgreSQL adapter contract.
    class MysqlAdapter < BaseAdapter
      # Numeric data types whose literal defaults are emitted unquoted
      NUMERIC_TYPES = %w[tinyint smallint mediumint int integer bigint decimal numeric float double real year].freeze

      # A relation in a canonical (SHOW CREATE VIEW) view definition: the identifier
      # after FROM or [STRAIGHT_]JOIN, past any opening parentheses
      VIEW_RELATION_REFERENCE = /(?<![\w`])(?:from|(?:straight_)?join)\s*(?:\(\s*)*`((?:[^`]|``)+)`/i

      # Generation expression of a column line in SHOW CREATE TABLE output
      GENERATED_EXPRESSION = /GENERATED ALWAYS AS \((.*)\) (?:VIRTUAL|STORED|PERSISTENT)\b/

      # Defaults that MySQL accepts without the parentheses required around other expressions
      TEMPORAL_DEFAULT = /\A(?:CURRENT_TIMESTAMP|NOW|LOCALTIME|LOCALTIMESTAMP)(?:\(\d*\))?\z/i

      # Introspection methods using information_schema

      # Fetch database extensions (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support extensions like PostgreSQL
      def fetch_extensions(_connection)
        []
      end

      # Fetch custom types (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support standalone custom types
      # @note MySQL has ENUM and SET types, but they are defined inline with columns, not as custom types
      def fetch_custom_types(_connection)
        []
      end

      # Fetch all tables from the current database
      #
      # Columns, primary keys and check constraints are fetched with one query each
      # for the whole schema, avoiding N+1 queries on large schemas.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :engine, :collation,
      #   :columns, :primary_key, :constraints
      def fetch_tables(connection)
        table_rows = connection.select_rows(<<~SQL.squish)
          SELECT TABLE_NAME, TABLE_SCHEMA, ENGINE, TABLE_COLLATION
          FROM information_schema.TABLES
          WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_TYPE = 'BASE TABLE'
          ORDER BY TABLE_NAME
        SQL
        return [] if table_rows.empty?

        columns_by_table = fetch_all_columns(connection)
        primary_keys_by_table = fetch_all_primary_keys(connection)
        constraints_by_table = fetch_all_constraints(connection)

        table_rows.map do |name, schema, engine, collation|
          columns = with_generation_expressions(connection, name, columns_by_table[name])
          json_columns = mariadb_json_columns(constraints_by_table[name])

          {
            name:,
            schema:,
            engine:,
            collation:,
            columns: columns.map { |column| json_columns.include?(column[:name]) ? as_json_column(column) : column },
            primary_key: primary_keys_by_table[name],
            constraints: constraints_by_table[name].reject { |constraint| json_columns.include?(constraint[:name]) }
          }
        end
      end

      # Fetch all secondary indexes from the current database
      #
      # Each index carries a complete CREATE INDEX :definition covering prefix
      # lengths, descending key parts, functional key parts (MySQL 8.0.13+),
      # FULLTEXT/SPATIAL indexes and invisible indexes.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :table, :name, :columns, :unique, :type, :definition
      def fetch_indexes(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME, NON_UNIQUE, INDEX_TYPE, SUB_PART, COLLATION,
                 #{index_expression_columns}
          FROM information_schema.STATISTICS
          WHERE TABLE_SCHEMA = DATABASE()
            AND INDEX_NAME != 'PRIMARY'
          ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX
        SQL

        rows.group_by { |row| row[0..1] }.map { |(table, name), parts| build_index(table, name, parts) }
      end

      # Fetch all foreign keys from the current database
      #
      # Composite foreign keys are returned as one entry whose :columns and
      # :foreign_columns list the columns in key order.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :columns, :foreign_table, :foreign_columns, :on_update, :on_delete
      def fetch_foreign_keys(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT
            kcu.TABLE_NAME,
            kcu.CONSTRAINT_NAME,
            kcu.COLUMN_NAME,
            kcu.REFERENCED_TABLE_NAME,
            kcu.REFERENCED_COLUMN_NAME,
            rc.UPDATE_RULE,
            rc.DELETE_RULE
          FROM information_schema.KEY_COLUMN_USAGE kcu
          JOIN information_schema.REFERENTIAL_CONSTRAINTS rc
            ON rc.CONSTRAINT_SCHEMA = kcu.TABLE_SCHEMA
            AND rc.TABLE_NAME = kcu.TABLE_NAME
            AND rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
          WHERE kcu.TABLE_SCHEMA = DATABASE()
            AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
          ORDER BY kcu.TABLE_NAME, kcu.CONSTRAINT_NAME, kcu.ORDINAL_POSITION
        SQL

        rows.group_by { |row| row[0..1] }.map { |(table, name), key_rows| build_foreign_key(table, name, key_rows) }
      end

      # Fetch all views from the current database, ordered so a view follows the views it reads
      #
      # The definition comes from SHOW CREATE VIEW, which (unlike
      # information_schema.VIEWS) does not qualify objects of the current
      # database with its name, so the dump loads into any database.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition, :check_option, :updatable
      def fetch_views(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT TABLE_NAME, CHECK_OPTION, IS_UPDATABLE
          FROM information_schema.VIEWS
          WHERE TABLE_SCHEMA = DATABASE()
          ORDER BY TABLE_NAME
        SQL

        views = rows.map do |name, check_option, updatable|
          {
            schema: 'public', # MySQL doesn't use schemas like PostgreSQL
            name:,
            definition: view_select(connection, name),
            check_option:,
            updatable: updatable == 'YES'
          }
        end
        order_by_dependencies(views, view_dependencies(connection, views))
      end

      # Fetch materialized views (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support materialized views
      def fetch_materialized_views(_connection)
        []
      end

      # Fetch all stored procedures and functions from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of routine hashes with :schema, :name, :definition
      def fetch_functions(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT ROUTINE_NAME, ROUTINE_TYPE
          FROM information_schema.ROUTINES
          WHERE ROUTINE_SCHEMA = DATABASE()
            AND ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')
          ORDER BY ROUTINE_NAME
        SQL

        rows.map do |name, type|
          {
            schema: 'public',
            name:,
            definition: show_create(connection, "SHOW CREATE #{type} #{quote_identifier(name)}", 2)
          }
        end
      end

      # Fetch sequences (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support sequences (uses AUTO_INCREMENT instead)
      def fetch_sequences(_connection)
        []
      end

      # Fetch all triggers from the current database
      #
      # Triggers sharing a table, timing and event are returned in firing order
      # (ACTION_ORDER) so that re-creating them in dump order keeps that order.
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger hashes with :table, :name, :event, :timing, :definition
      def fetch_triggers(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
          FROM information_schema.TRIGGERS
          WHERE TRIGGER_SCHEMA = DATABASE()
          ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION, ACTION_ORDER
        SQL

        rows.map do |name, event, table, timing|
          {
            table:,
            name:,
            event:,
            timing:,
            definition: show_create(connection, "SHOW CREATE TRIGGER #{quote_identifier(name)}", 2)
          }
        end
      end

      # Fetch comments on database objects
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash] Hash with object types as keys (:tables, :columns)
      def fetch_comments(connection)
        {
          tables: fetch_table_comments(connection),
          columns: fetch_column_comments(connection),
          indexes: {},  # MySQL doesn't support index comments via information_schema
          views: {},    # MySQL doesn't expose view comments via information_schema
          functions: {}, # MySQL doesn't expose function comments via information_schema
          procedures: {}
        }
      end

      # Capability methods - MySQL feature support

      # Indicates whether MySQL supports extensions
      #
      # @return [Boolean] Always false for MySQL
      def supports_extensions?
        false
      end

      # Indicates whether MySQL supports materialized views
      #
      # @return [Boolean] Always false for MySQL
      def supports_materialized_views?
        false
      end

      # Indicates whether MySQL supports custom types
      #
      # @return [Boolean] Always false (ENUM/SET are inline with columns, not custom types)
      def supports_custom_types?
        false
      end

      # Indicates whether MySQL supports domains
      #
      # @return [Boolean] Always false for MySQL
      def supports_domains?
        false
      end

      # Indicates whether MySQL supports stored procedures and functions
      #
      # @return [Boolean] Always true for MySQL
      def supports_functions?
        true
      end

      # Indicates whether MySQL supports triggers
      #
      # @return [Boolean] Always true for MySQL
      def supports_triggers?
        true
      end

      # Indicates whether MySQL supports sequences
      #
      # @return [Boolean] Always false (uses AUTO_INCREMENT instead)
      def supports_sequences?
        false
      end

      # Indicates whether MySQL supports check constraints
      #
      # @return [Boolean] True for MySQL 8.0.16+ and MariaDB 10.2+
      def supports_check_constraints?
        version_at_least?(database_version, mariadb? ? '10.2' : '8.0.16')
      end

      # Indicates whether MySQL supports comments on database objects
      #
      # @return [Boolean] Always true for MySQL (tables and columns only)
      def supports_comments?
        true
      end

      # Indicates whether the server is MariaDB rather than Oracle MySQL
      #
      # @return [Boolean] True when VERSION() reports a MariaDB server
      def mariadb?
        server_version.include?('MariaDB')
      end

      # Version detection

      # Get the current MySQL database version
      #
      # @return [String] Normalized version string (e.g., "8.0.35")
      def database_version
        @database_version ||= parse_version(server_version)
      end

      # Parse MySQL version string into normalized format
      #
      # @param version_string [String] Raw version string from MySQL (e.g., "8.0.35" or "5.7.44-log")
      # @return [String] Normalized version (e.g., "8.0.35") or "unknown" if parsing fails
      def parse_version(version_string)
        match = version_string.match(/(\d+\.\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Raw VERSION() string, e.g. "8.0.35" or "11.4.2-MariaDB-ubu2404"
      #
      # @return [String]
      def server_version
        @server_version ||= connection.select_value('SELECT VERSION()')
      end

      # Batch fetch all columns of the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of column hashes
      def fetch_all_columns(connection)
        rows = connection.select_all(<<~SQL.squish)
          SELECT
            TABLE_NAME, COLUMN_NAME, DATA_TYPE, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA,
            CHARACTER_SET_NAME, COLLATION_NAME,
            CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
          FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE()
          ORDER BY TABLE_NAME, ORDINAL_POSITION
        SQL

        rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, result|
          result[row['TABLE_NAME']] << build_column(row)
        end
      end

      # Build a column hash from an information_schema.COLUMNS row
      #
      # @param row [Hash] information_schema.COLUMNS row keyed by column name
      # @return [Hash] Column hash; :type is the full COLUMN_TYPE (e.g. "int unsigned",
      #   "datetime(6)", "enum('a','b')") and :default is a SQL fragment
      def build_column(row)
        extra = row['EXTRA']
        {
          name: row['COLUMN_NAME'],
          type: row['COLUMN_TYPE'],
          data_type: row['DATA_TYPE'],
          nullable: row['IS_NULLABLE'] == 'YES',
          default: column_default_sql(row['DATA_TYPE'], row['COLUMN_DEFAULT'], extra),
          length: row['CHARACTER_MAXIMUM_LENGTH'],
          precision: row['NUMERIC_PRECISION'],
          scale: row['NUMERIC_SCALE'],
          column_type: row['COLUMN_TYPE'],
          extra:,
          auto_increment: extra.include?('auto_increment'),
          on_update: extra[/on update (.+)\z/i, 1],
          generated: generated_column(extra),
          charset: row['CHARACTER_SET_NAME'],
          collation: row['COLLATION_NAME']
        }
      end

      # Convert COLUMN_DEFAULT into the SQL that recreates it
      #
      # MySQL stores literal defaults unquoted and flags expression defaults
      # with DEFAULT_GENERATED; MariaDB already stores SQL (quoted literals,
      # bare expressions, and the string 'NULL' for no default).
      #
      # @return [String, nil] SQL default fragment or nil when the column has no default
      def column_default_sql(data_type, default, extra)
        return mariadb_default(default) if mariadb?
        return nil if default.nil?
        return expression_default(unescape_expression(default)) if extra.include?('DEFAULT_GENERATED')
        return default if data_type == 'bit' || NUMERIC_TYPES.include?(data_type)

        quote_string(default)
      end

      # @return [String, nil] MariaDB default (already SQL) or nil for NULL
      def mariadb_default(default)
        default unless default.nil? || default == 'NULL'
      end

      # Wrap expression defaults in parentheses, as MySQL 8.0.13+ requires
      #
      # @return [String] SQL default fragment
      def expression_default(expression)
        TEMPORAL_DEFAULT.match?(expression) ? expression : "(#{expression})"
      end

      # @return [Hash, nil] { kind: } for generated columns, kind being "STORED" or
      #   "VIRTUAL" (MariaDB's PERSISTENT is its alias for STORED); the expression
      #   is added by #with_generation_expressions
      def generated_column(extra)
        storage = extra[/\b(VIRTUAL|STORED|PERSISTENT) GENERATED\b/i, 1]
        return nil unless storage

        { kind: storage.casecmp?('VIRTUAL') ? 'VIRTUAL' : 'STORED' }
      end

      # Add generation expressions to a table's generated columns
      #
      # information_schema.COLUMNS.GENERATION_EXPRESSION keeps the expression as
      # the creating session printed it (its charset introducers, no implicit
      # CONVERT), which MySQL canonicalizes differently once the dump is loaded.
      # SHOW CREATE TABLE prints the canonical form, keeping dump/load/dump stable.
      #
      # @return [Array<Hash>] The columns, generated ones carrying :expression
      def with_generation_expressions(connection, table, columns)
        return columns if columns.none? { |column| column[:generated] }

        create_table = show_create(connection, "SHOW CREATE TABLE #{quote_identifier(table)}", 1)
        columns.each do |column|
          next unless column[:generated]

          line = create_table.lines.find { |text| text.start_with?("  #{quote_identifier(column[:name])} ") }
          column[:generated][:expression] = line&.[](GENERATED_EXPRESSION, 1)
          raise Error, "Unable to find expression of generated column #{table}.#{column[:name]}" unless column[:generated][:expression]
        end
      end

      # Batch fetch all primary keys of the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, Array<String>>] Hash of table_name => primary key column names in key order
      def fetch_all_primary_keys(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT TABLE_NAME, COLUMN_NAME
          FROM information_schema.KEY_COLUMN_USAGE
          WHERE TABLE_SCHEMA = DATABASE()
            AND CONSTRAINT_NAME = 'PRIMARY'
          ORDER BY TABLE_NAME, ORDINAL_POSITION
        SQL

        rows.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |(table, column), result|
          result[table] << column
        end
      end

      # Batch fetch all CHECK constraints of the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, Array<Hash>>] Hash of table_name => constraint hashes whose
      #   :definition is a complete "CHECK (...)" clause
      def fetch_all_constraints(connection)
        result = Hash.new { |hash, key| hash[key] = [] }
        return result unless supports_check_constraints?

        connection.select_rows(check_constraints_query).each do |table, name, clause, enforced|
          definition = "CHECK (#{unescape_expression(clause)})"
          definition += ' NOT ENFORCED' if enforced == 'NO'
          result[table] << { name:, definition:, type: :check }
        end
        result
      end

      # MariaDB implements JSON as LONGTEXT plus a column-level CHECK
      # (json_valid(`col`)) named after the column; such columns are dumped as
      # JSON so loading recreates exactly that, not a table-level constraint.
      #
      # @param constraints [Array<Hash>] A table's CHECK constraints
      # @return [Array<String>] Names of the table's JSON columns
      def mariadb_json_columns(constraints)
        return [] unless mariadb?

        constraints.select { |constraint| constraint[:definition] == "CHECK (json_valid(`#{constraint[:name]}`))" }
                   .pluck(:name)
      end

      # @return [Hash] Column hash declared as JSON (charset and collation are implied)
      def as_json_column(column)
        column.merge(type: 'json', charset: nil, collation: nil)
      end

      # MySQL keys CHECK constraints by schema (TABLE_NAME lives in TABLE_CONSTRAINTS);
      # MariaDB keys them by table and has no ENFORCED column.
      #
      # @return [String] SQL query returning table, name, clause, enforced
      def check_constraints_query
        if mariadb?
          <<~SQL.squish
            SELECT TABLE_NAME, CONSTRAINT_NAME, CHECK_CLAUSE, 'YES'
            FROM information_schema.CHECK_CONSTRAINTS
            WHERE CONSTRAINT_SCHEMA = DATABASE()
            ORDER BY TABLE_NAME, CONSTRAINT_NAME
          SQL
        else
          <<~SQL.squish
            SELECT tc.TABLE_NAME, cc.CONSTRAINT_NAME, cc.CHECK_CLAUSE, tc.ENFORCED
            FROM information_schema.TABLE_CONSTRAINTS tc
            JOIN information_schema.CHECK_CONSTRAINTS cc
              ON cc.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
              AND cc.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
            WHERE tc.TABLE_SCHEMA = DATABASE()
              AND tc.CONSTRAINT_TYPE = 'CHECK'
            ORDER BY tc.TABLE_NAME, cc.CONSTRAINT_NAME
          SQL
        end
      end

      # STATISTICS.EXPRESSION and IS_VISIBLE exist only on MySQL 8.0.13+
      #
      # @return [String] SELECT list fragment yielding expression and visibility
      def index_expression_columns
        if !mariadb? && version_at_least?(database_version, '8.0.13')
          'EXPRESSION, IS_VISIBLE'
        else
          "NULL AS EXPRESSION, 'YES' AS IS_VISIBLE"
        end
      end

      # Build an index hash from its STATISTICS rows (one per key part)
      #
      # @return [Hash] Index hash with complete :definition
      def build_index(table, name, parts)
        _table, _name, _column, non_unique, index_type, = parts.first
        unique = non_unique.to_i.zero?
        key_parts = parts.map { |part| index_key_part(*part.values_at(2, 5, 6, 7)) }
        visibility = parts.first[8] == 'NO' ? ' INVISIBLE' : ''

        {
          table:,
          name:,
          columns: parts.filter_map { |part| part[2] },
          unique:,
          type: index_type,
          definition: "CREATE #{index_kind(index_type, unique)}INDEX #{quote_identifier(name)} " \
                      "ON #{quote_identifier(table)} (#{key_parts.join(', ')})#{visibility}"
        }
      end

      # @return [String] One key part: `col`, `col`(10), (expression), optionally DESC
      def index_key_part(column, sub_part, collation, expression)
        part = expression ? "(#{unescape_expression(expression)})" : quote_identifier(column)
        part += "(#{sub_part})" if sub_part
        part += ' DESC' if collation == 'D'
        part
      end

      # @return [String] Index modifier keyword ("UNIQUE ", "FULLTEXT ", "SPATIAL " or "")
      def index_kind(index_type, unique)
        return "#{index_type} " if %w[FULLTEXT SPATIAL].include?(index_type)

        unique ? 'UNIQUE ' : ''
      end

      # Build a foreign key hash from its KEY_COLUMN_USAGE rows (one per column)
      #
      # @return [Hash] Foreign key hash
      def build_foreign_key(table, name, key_rows)
        _table, _name, _column, foreign_table, _foreign_column, on_update, on_delete = key_rows.first

        {
          table:,
          name:,
          columns: key_rows.pluck(2),
          foreign_table:,
          foreign_columns: key_rows.pluck(4),
          on_update:,
          on_delete:
        }
      end

      # Extract the SELECT statement (plus any WITH CHECK OPTION) from SHOW CREATE VIEW
      #
      # @return [String] View query
      # @raise [Error] If the statement cannot be parsed
      def view_select(connection, name)
        create_statement = show_create(connection, "SHOW CREATE VIEW #{quote_identifier(name)}", 1)
        select = create_statement[/\sVIEW\s+`(?:[^`]|``)+`\s+AS\s+(.*)\z/m, 1]
        raise Error, "Unable to parse definition of view #{name}: #{create_statement}" unless select

        select
      end

      # Which views of the current database each view reads
      #
      # information_schema.VIEW_TABLE_USAGE exists on MySQL 8.0.13+ only. On
      # MariaDB and older MySQL the view's own definition is scanned instead:
      # SHOW CREATE VIEW backtick-quotes every identifier and writes every
      # relation right after FROM or JOIN (comma joins become JOIN), so only
      # those count. A column alias, table alias or qualifier named like
      # another view is not a reference: as an edge it could close a cycle
      # and put a view before the view it reads.
      #
      # @param views [Array<Hash>] Views with :name and :definition
      # @return [Hash<String, Array<String>>] View name => names of views it reads
      def view_dependencies(connection, views)
        return view_table_usage(connection) if !mariadb? && version_at_least?(database_version, '8.0.13')

        names = views.to_set { |view| view[:name] }
        views.to_h do |view|
          referenced = view[:definition].scan(VIEW_RELATION_REFERENCE).flatten.map { |name| name.gsub('``', '`') }
          [view[:name], referenced.select { |name| names.include?(name) }.uniq - [view[:name]]]
        end
      end

      # @return [Hash<String, Array<String>>] View name => names of the relations it reads
      def view_table_usage(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT VIEW_NAME, TABLE_NAME
          FROM information_schema.VIEW_TABLE_USAGE
          WHERE VIEW_SCHEMA = DATABASE() AND TABLE_SCHEMA = DATABASE()
          ORDER BY VIEW_NAME, TABLE_NAME
        SQL

        rows.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
      end

      # Run a SHOW CREATE statement and return its CREATE statement column
      #
      # @param column [Integer] Result column holding the statement (views: 1;
      #   routines and triggers, which report sql_mode first: 2)
      # @return [String] CREATE statement
      # @raise [Error] If the statement is hidden (missing privileges)
      def show_create(connection, statement, column)
        create_statement = connection.select_rows(statement).first&.at(column)
        raise Error, "#{statement} returned no definition; check the user's privileges" if create_statement.nil?

        create_statement
      end

      # MySQL's information_schema escapes quotes and backslashes inside
      # expressions (CHECK_CLAUSE, expression defaults)
      # as if they were string literals; undo it to get the SQL SHOW CREATE
      # TABLE shows. MariaDB stores the SQL unescaped.
      #
      # @return [String] SQL expression
      def unescape_expression(expression)
        return expression if mariadb?

        expression.gsub(/\\([\\'])/, '\1')
      end

      # @return [String] Single-quoted MySQL string literal
      def quote_string(value)
        "'#{value.gsub(/[\\']/) { |char| char * 2 }}'"
      end

      # @return [String] Backtick-quoted identifier
      def quote_identifier(name)
        "`#{name.gsub('`', '``')}`"
      end

      # Fetch comments on tables
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<String, String>] Hash of table_name => comment
      def fetch_table_comments(connection)
        connection.select_rows(<<~SQL.squish).to_h
          SELECT TABLE_NAME, TABLE_COMMENT
          FROM information_schema.TABLES
          WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_TYPE = 'BASE TABLE'
            AND TABLE_COMMENT != ''
          ORDER BY TABLE_NAME
        SQL
      end

      # Fetch comments on columns
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Hash<Array(String, String), String>] Hash of [table_name, column_name] => comment
      def fetch_column_comments(connection)
        rows = connection.select_rows(<<~SQL.squish)
          SELECT TABLE_NAME, COLUMN_NAME, COLUMN_COMMENT
          FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE()
            AND COLUMN_COMMENT != ''
          ORDER BY TABLE_NAME, ORDINAL_POSITION
        SQL

        rows.to_h { |table, column, comment| [[table, column], comment] }
      end
    end
  end
end
