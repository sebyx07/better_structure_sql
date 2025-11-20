# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # MySQL adapter implementing introspection via information_schema and MySQL system tables.
    #
    # Provides MySQL-specific SQL generation with proper dialect support.
    # This adapter handles MySQL's unique features including stored procedures, triggers,
    # ENUM/SET types, and AUTO_INCREMENT sequences.
    class MysqlAdapter < BaseAdapter
      # Introspection methods using information_schema

      # Fetch database extensions (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support extensions like PostgreSQL
      def fetch_extensions(_connection)
        # MySQL doesn't support extensions like PostgreSQL
        []
      end

      # Fetch custom types (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support standalone custom types
      # @note MySQL has ENUM and SET types, but they are defined inline with columns, not as custom types
      def fetch_custom_types(_connection)
        # MySQL has limited support for custom types (ENUM and SET are inline)
        # Return empty array since ENUMs/SETs are defined per-column
        []
      end

      # Fetch all tables from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of table hashes with :name, :schema, :columns, :primary_key, :constraints
      def fetch_tables(connection)
        # Performance optimized: Batches all table metadata queries to avoid N+1 queries
        # For 1000 tables: 4 queries instead of 3001 queries (~750x faster)
        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            TABLE_SCHEMA
          FROM information_schema.TABLES
          WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_TYPE = 'BASE TABLE'
          ORDER BY TABLE_NAME
        SQL

        table_rows = connection.execute(query).to_a
        return [] if table_rows.empty?

        table_names = table_rows.pluck(0)

        # Batch fetch all columns, primary keys, and constraints
        columns_by_table = fetch_all_columns(connection, table_names)
        primary_keys_by_table = fetch_all_primary_keys(connection, table_names)
        constraints_by_table = fetch_all_constraints(connection, table_names)

        # Combine results
        table_rows.map do |row|
          table_name = row[0] # MySQL returns arrays not hashes by default
          {
            name: table_name,
            schema: row[1],
            columns: columns_by_table[table_name] || [],
            primary_key: primary_keys_by_table[table_name] || [],
            constraints: constraints_by_table[table_name] || []
          }
        end
      end

      # Fetch all indexes from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of index hashes with :table, :name, :columns, :unique, :type
      def fetch_indexes(connection)
        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            INDEX_NAME,
            COLUMN_NAME,
            SEQ_IN_INDEX,
            NON_UNIQUE,
            INDEX_TYPE
          FROM information_schema.STATISTICS
          WHERE TABLE_SCHEMA = DATABASE()
            AND INDEX_NAME != 'PRIMARY'
          ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX
        SQL

        # Group by table and index name to build multi-column indexes
        indexes_by_key = {}

        connection.execute(query).each do |row|
          table_name = row[0]
          index_name = row[1]
          column_name = row[2]
          # seq_in_index = row[3] # Used for ordering, handled by ORDER BY in query
          non_unique = row[4]
          index_type = row[5]

          key = "#{table_name}.#{index_name}"
          indexes_by_key[key] ||= {
            table: table_name,
            name: index_name,
            columns: [],
            unique: non_unique.to_i.zero?,
            type: index_type
          }
          indexes_by_key[key][:columns] << column_name
        end

        indexes_by_key.values
      end

      # Fetch all foreign keys from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of foreign key hashes with :table, :name, :column, :foreign_table, :foreign_column, :on_update, :on_delete
      def fetch_foreign_keys(connection)
        query = <<~SQL.squish
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
            ON kcu.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
            AND kcu.TABLE_SCHEMA = rc.CONSTRAINT_SCHEMA
          WHERE kcu.TABLE_SCHEMA = DATABASE()
            AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
          ORDER BY kcu.TABLE_NAME, kcu.CONSTRAINT_NAME
        SQL

        connection.execute(query).map do |row|
          {
            table: row[0],
            name: row[1],
            column: row[2],
            foreign_table: row[3],
            foreign_column: row[4],
            on_update: row[5],
            on_delete: row[6]
          }
        end
      end

      # Fetch all views from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of view hashes with :schema, :name, :definition, :check_option, :updatable
      def fetch_views(connection)
        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            VIEW_DEFINITION,
            CHECK_OPTION,
            IS_UPDATABLE
          FROM information_schema.VIEWS
          WHERE TABLE_SCHEMA = DATABASE()
          ORDER BY TABLE_NAME
        SQL

        connection.execute(query).map do |row|
          {
            schema: 'public', # MySQL doesn't use schemas like PostgreSQL
            name: row[0],
            definition: row[1],
            check_option: row[2],
            updatable: row[3] == 'YES'
          }
        end
      end

      # Fetch materialized views (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support materialized views
      def fetch_materialized_views(_connection)
        # MySQL doesn't support materialized views
        []
      end

      # Fetch all stored procedures and functions from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of routine hashes with :schema, :name, :definition
      def fetch_functions(connection)
        query = <<~SQL.squish
          SELECT
            ROUTINE_NAME,
            ROUTINE_TYPE
          FROM information_schema.ROUTINES
          WHERE ROUTINE_SCHEMA = DATABASE()
            AND ROUTINE_TYPE IN ('PROCEDURE', 'FUNCTION')
          ORDER BY ROUTINE_NAME
        SQL

        connection.execute(query).map do |row|
          routine_name = row[0]
          routine_type = row[1]

          # Get complete CREATE statement using SHOW CREATE
          create_query = if routine_type == 'PROCEDURE'
                           "SHOW CREATE PROCEDURE `#{routine_name}`"
                         else
                           "SHOW CREATE FUNCTION `#{routine_name}`"
                         end

          create_result = connection.execute(create_query).first
          # SHOW CREATE returns: [procedure_name, sql_mode, create_statement, ...]
          create_statement = create_result[2] if create_result

          {
            schema: 'public',
            name: routine_name,
            definition: create_statement
          }
        end
      end

      # Fetch sequences (not supported in MySQL)
      #
      # @param _connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection (unused)
      # @return [Array] Empty array as MySQL doesn't support sequences (uses AUTO_INCREMENT instead)
      def fetch_sequences(_connection)
        # MySQL doesn't have sequences (uses AUTO_INCREMENT)
        []
      end

      # Fetch all triggers from the current database
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @return [Array<Hash>] Array of trigger hashes with :table, :name, :event, :timing, :definition
      def fetch_triggers(connection)
        query = <<~SQL.squish
          SELECT
            TRIGGER_NAME,
            EVENT_MANIPULATION,
            EVENT_OBJECT_TABLE,
            ACTION_TIMING
          FROM information_schema.TRIGGERS
          WHERE TRIGGER_SCHEMA = DATABASE()
          ORDER BY EVENT_OBJECT_TABLE, TRIGGER_NAME
        SQL

        connection.execute(query).map do |row|
          trigger_name = row[0]

          # Get complete CREATE statement using SHOW CREATE
          create_result = connection.execute("SHOW CREATE TRIGGER `#{trigger_name}`").first
          # SHOW CREATE TRIGGER returns: [trigger_name, sql_mode, create_statement, ...]
          create_statement = create_result[2] if create_result

          {
            table: row[2],
            name: trigger_name,
            event: row[1],     # INSERT, UPDATE, DELETE
            timing: row[3],    # BEFORE, AFTER
            definition: create_statement
          }
        end
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
        false # ENUM/SET are inline with columns, not custom types
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
        true # Stored procedures and functions
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
        false # Uses AUTO_INCREMENT instead
      end

      # Indicates whether MySQL supports check constraints
      #
      # @return [Boolean] True for MySQL 8.0.16+, false for earlier versions
      def supports_check_constraints?
        version_at_least?(database_version, '8.0.16')
      end

      # Version detection

      # Get the current MySQL database version
      #
      # @return [String] Normalized version string (e.g., "8.0.35")
      def database_version
        @database_version ||= begin
          version_string = connection.select_value('SELECT VERSION()')
          parse_version(version_string)
        end
      end

      # Parse MySQL version string into normalized format
      #
      # @param version_string [String] Raw version string from MySQL (e.g., "8.0.35" or "5.7.44-log")
      # @return [String] Normalized version (e.g., "8.0.35") or "unknown" if parsing fails
      def parse_version(version_string)
        # Example: "8.0.35" or "5.7.44-log"
        # Extract major.minor.patch version
        match = version_string.match(/(\d+\.\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Helper methods for introspection

      # Fetch columns for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of column hashes with :name, :type, :nullable, :default, etc.
      def fetch_columns(connection, table_name)
        query = <<~SQL.squish
          SELECT
            COLUMN_NAME,
            DATA_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            CHARACTER_MAXIMUM_LENGTH,
            NUMERIC_PRECISION,
            NUMERIC_SCALE,
            COLUMN_TYPE,
            EXTRA
          FROM information_schema.COLUMNS
          WHERE TABLE_NAME = #{connection.quote(table_name)}
            AND TABLE_SCHEMA = DATABASE()
          ORDER BY ORDINAL_POSITION
        SQL

        connection.execute(query).map do |row|
          {
            name: row[0],
            type: resolve_column_type(row),
            nullable: row[2] == 'YES',
            default: row[3],
            length: row[4],
            precision: row[5],
            scale: row[6],
            column_type: row[7], # Full type with ENUM values, etc.
            extra: row[8] # AUTO_INCREMENT, etc.
          }
        end
      end

      # Fetch primary key columns for a specific table
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<String>] Array of primary key column names
      def fetch_primary_key(connection, table_name)
        query = <<~SQL.squish
          SELECT COLUMN_NAME
          FROM information_schema.KEY_COLUMN_USAGE
          WHERE TABLE_NAME = #{connection.quote(table_name)}
            AND TABLE_SCHEMA = DATABASE()
            AND CONSTRAINT_NAME = 'PRIMARY'
          ORDER BY ORDINAL_POSITION
        SQL

        connection.execute(query).pluck(0)
      end

      # Fetch check constraints for a specific table (MySQL 8.0.16+)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_name [String] Name of the table
      # @return [Array<Hash>] Array of constraint hashes with :name, :definition, :type
      def fetch_constraints(connection, table_name)
        # MySQL 8.0.16+ supports check constraints
        return [] unless supports_check_constraints?

        query = <<~SQL.squish
          SELECT
            CONSTRAINT_NAME,
            CHECK_CLAUSE
          FROM information_schema.CHECK_CONSTRAINTS
          WHERE CONSTRAINT_SCHEMA = DATABASE()
            AND TABLE_NAME = #{connection.quote(table_name)}
          ORDER BY CONSTRAINT_NAME
        SQL

        connection.execute(query).map do |row|
          {
            name: row[0],
            definition: row[1],
            type: :check
          }
        end
      rescue StandardError
        # If CHECK_CONSTRAINTS table doesn't exist (MySQL < 8.0.16), return empty
        []
      end

      # Batch fetch all columns for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<Hash>>] Hash of table_name => array of column hashes
      def fetch_all_columns(connection, table_names)
        return {} if table_names.empty?

        # Build IN clause with quoted table names
        quoted_names = table_names.map { |t| connection.quote(t) }.join(', ')

        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            COLUMN_NAME,
            DATA_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            CHARACTER_MAXIMUM_LENGTH,
            NUMERIC_PRECISION,
            NUMERIC_SCALE,
            COLUMN_TYPE,
            EXTRA,
            ORDINAL_POSITION
          FROM information_schema.COLUMNS
          WHERE TABLE_NAME IN (#{quoted_names})
            AND TABLE_SCHEMA = DATABASE()
          ORDER BY TABLE_NAME, ORDINAL_POSITION
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.execute(query).each do |row|
          # Build row array compatible with resolve_column_type expectations
          # resolve_column_type expects: [nil, DATA_TYPE, nil, nil, LENGTH, PRECISION, SCALE, COLUMN_TYPE]
          column_row = [nil, row[2], nil, nil, row[5], row[6], row[7], row[8]]

          result[row[0]] << {
            name: row[1],
            type: resolve_column_type(column_row),
            nullable: row[3] == 'YES',
            default: row[4],
            length: row[5],
            precision: row[6],
            scale: row[7],
            column_type: row[8],
            extra: row[9]
          }
        end

        result
      end

      # Batch fetch all primary keys for multiple tables (performance optimization)
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] Database connection
      # @param table_names [Array<String>] Array of table names
      # @return [Hash<String, Array<String>>] Hash of table_name => array of primary key column names
      def fetch_all_primary_keys(connection, table_names)
        return {} if table_names.empty?

        quoted_names = table_names.map { |t| connection.quote(t) }.join(', ')

        query = <<~SQL.squish
          SELECT TABLE_NAME, COLUMN_NAME, ORDINAL_POSITION
          FROM information_schema.KEY_COLUMN_USAGE
          WHERE TABLE_NAME IN (#{quoted_names})
            AND TABLE_SCHEMA = DATABASE()
            AND CONSTRAINT_NAME = 'PRIMARY'
          ORDER BY TABLE_NAME, ORDINAL_POSITION
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.execute(query).each do |row|
          result[row[0]] << row[1]
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
        return {} unless supports_check_constraints? # MySQL < 8.0.16

        quoted_names = table_names.map { |t| connection.quote(t) }.join(', ')

        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            CONSTRAINT_NAME,
            CHECK_CLAUSE
          FROM information_schema.CHECK_CONSTRAINTS
          WHERE CONSTRAINT_SCHEMA = DATABASE()
            AND TABLE_NAME IN (#{quoted_names})
          ORDER BY TABLE_NAME, CONSTRAINT_NAME
        SQL

        result = Hash.new { |h, k| h[k] = [] }

        connection.execute(query).each do |row|
          result[row[0]] << {
            name: row[1],
            definition: row[2],
            type: :check
          }
        end

        result
      rescue StandardError
        # If CHECK_CONSTRAINTS table doesn't exist, return empty hash
        {}
      end

      # Resolve MySQL column type into normalized format
      #
      # @param row [Array] Column information row from information_schema.COLUMNS
      # @return [String] Normalized column type with length/precision if applicable
      def resolve_column_type(row)
        data_type = row[1]
        column_type = row[7] # Full type definition

        case data_type
        when 'varchar', 'char'
          # Use CHARACTER_MAXIMUM_LENGTH
          length = row[4]
          length ? "#{data_type}(#{length})" : data_type
        when 'decimal', 'numeric'
          precision = row[5]
          scale = row[6]
          if precision && scale
            "#{data_type}(#{precision},#{scale})"
          else
            data_type
          end
        when 'enum', 'set'
          # Return full column_type which includes values: enum('admin','user','guest')
          column_type
        when 'int', 'integer'
          'int'
        when 'bigint'
          'bigint'
        when 'tinyint'
          # Check if it's boolean (tinyint(1))
          column_type.include?('tinyint(1)') ? 'boolean' : 'tinyint'
        when 'datetime', 'timestamp'
          data_type
        when 'text', 'mediumtext', 'longtext'
          data_type
        when 'blob', 'mediumblob', 'longblob'
          data_type
        when 'json'
          'json'
        else
          data_type
        end
      end
    end
  end
end
