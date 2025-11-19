# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # MySQL adapter implementing introspection via information_schema and MySQL system tables.
    # Provides MySQL-specific SQL generation with proper dialect support.
    class MysqlAdapter < BaseAdapter
      # Introspection methods using information_schema

      def fetch_extensions(_connection)
        # MySQL doesn't support extensions like PostgreSQL
        []
      end

      def fetch_custom_types(_connection)
        # MySQL has limited support for custom types (ENUM and SET are inline)
        # Return empty array since ENUMs/SETs are defined per-column
        []
      end

      def fetch_tables(connection)
        query = <<~SQL.squish
          SELECT
            TABLE_NAME,
            TABLE_SCHEMA
          FROM information_schema.TABLES
          WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_TYPE = 'BASE TABLE'
          ORDER BY TABLE_NAME
        SQL

        connection.execute(query).map do |row|
          table_name = row[0] # MySQL returns arrays not hashes by default
          {
            name: table_name,
            schema: row[1],
            columns: fetch_columns(connection, table_name),
            primary_key: fetch_primary_key(connection, table_name),
            constraints: fetch_constraints(connection, table_name)
          }
        end
      end

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

      def fetch_materialized_views(_connection)
        # MySQL doesn't support materialized views
        []
      end

      def fetch_functions(_connection)
        # MySQL stored procedures and functions are typically managed via migrations
        # in Rails apps, not dumped to structure.sql. This avoids DELIMITER issues
        # and permission problems with DEFINER clauses.
        #
        # If you need to dump procedures, define them in a migration file instead.
        []
      end

      def fetch_sequences(_connection)
        # MySQL doesn't have sequences (uses AUTO_INCREMENT)
        []
      end

      def fetch_triggers(_connection)
        # MySQL triggers are typically managed via migrations in Rails apps,
        # not dumped to structure.sql. This is consistent with Rails' default behavior
        # and avoids complexity with trigger definitions.
        #
        # If you need to dump triggers, define them in a migration file instead.
        []
      end

      # Capability methods - MySQL feature support

      def supports_extensions?
        false
      end

      def supports_materialized_views?
        false
      end

      def supports_custom_types?
        false # ENUM/SET are inline with columns, not custom types
      end

      def supports_domains?
        false
      end

      def supports_functions?
        true # Stored procedures and functions
      end

      def supports_triggers?
        true
      end

      def supports_sequences?
        false # Uses AUTO_INCREMENT instead
      end

      # Does this database support check constraints?
      # @return [Boolean] True for MySQL 8.0.16+
      def supports_check_constraints?
        version_at_least?(database_version, '8.0.16')
      end

      # Version detection

      def database_version
        @database_version ||= begin
          version_string = connection.select_value('SELECT VERSION()')
          parse_version(version_string)
        end
      end

      def parse_version(version_string)
        # Example: "8.0.35" or "5.7.44-log"
        # Extract major.minor.patch version
        match = version_string.match(/(\d+\.\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Helper methods for introspection

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
