# frozen_string_literal: true

module BetterStructureSql
  module Adapters
    # SQLite adapter implementing introspection via sqlite_master and PRAGMA statements.
    # Provides SQLite-specific SQL generation with proper dialect support.
    class SqliteAdapter < BaseAdapter
      # Introspection methods using sqlite_master and PRAGMA

      def fetch_extensions(_connection)
        # SQLite doesn't support extensions like PostgreSQL
        []
      end

      def fetch_custom_types(_connection)
        # SQLite doesn't support custom types
        []
      end

      def fetch_tables(connection)
        query = <<~SQL.squish
          SELECT name, sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name NOT LIKE 'sqlite_%'
            AND name != 'schema_migrations'
            AND name != 'ar_internal_metadata'
          ORDER BY name
        SQL

        connection.execute(query).map do |row|
          table_name = row[0]
          {
            name: table_name,
            schema: 'main',
            sql: row[1],
            columns: fetch_columns(connection, table_name),
            primary_key: fetch_primary_key(connection, table_name),
            constraints: fetch_constraints(connection, table_name)
          }
        end
      end

      def fetch_indexes(connection)
        tables = fetch_table_names(connection)
        indexes = []
        skip_origins = %w[pk u].freeze

        tables.each do |table_name|
          # Get list of indexes for this table
          index_list = connection.execute("PRAGMA index_list(#{connection.quote(table_name)})")

          index_list.each do |index_row|
            index_name = index_row[1]
            is_unique = index_row[2].to_i == 1
            origin = index_row[3] # 'c' = CREATE INDEX, 'u' = UNIQUE constraint, 'pk' = PRIMARY KEY

            # Skip auto-generated indexes for PRIMARY KEY and UNIQUE constraints
            next if skip_origins.include?(origin)

            # Get columns for this index
            index_info = connection.execute("PRAGMA index_info(#{connection.quote(index_name)})")
            columns = index_info.map { |col_row| col_row[2] }

            indexes << {
              table: table_name,
              name: index_name,
              columns: columns,
              unique: is_unique,
              type: 'BTREE' # SQLite uses B-tree by default
            }
          end
        end

        indexes
      end

      def fetch_foreign_keys(connection)
        tables = fetch_table_names(connection)
        foreign_keys = []

        tables.each do |table_name|
          fk_list = connection.execute("PRAGMA foreign_key_list(#{connection.quote(table_name)})")

          fk_list.each do |fk_row|
            foreign_keys << {
              table: table_name,
              name: "fk_#{table_name}_#{fk_row[2]}_#{fk_row[3]}", # Generate name
              column: fk_row[3],
              foreign_table: fk_row[2],
              foreign_column: fk_row[4],
              on_update: fk_row[5],
              on_delete: fk_row[6]
            }
          end
        end

        foreign_keys
      end

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
            name: row[0],
            definition: row[1],
            updatable: false # SQLite views are generally not updatable
          }
        end
      end

      def fetch_materialized_views(_connection)
        # SQLite doesn't support materialized views
        []
      end

      def fetch_functions(_connection)
        # SQLite doesn't support stored procedures/functions (only user-defined functions in C/Ruby)
        []
      end

      def fetch_sequences(_connection)
        # SQLite doesn't have sequences (uses AUTOINCREMENT)
        []
      end

      def fetch_triggers(connection)
        query = <<~SQL.squish
          SELECT name, tbl_name, sql
          FROM sqlite_master
          WHERE type = 'trigger'
          ORDER BY tbl_name, name
        SQL

        connection.execute(query).map do |row|
          # Parse timing and event from SQL
          sql = row[2]
          timing_match = sql.match(/\b(BEFORE|AFTER|INSTEAD OF)\b/i)
          timing = timing_match ? timing_match.captures.first.upcase : 'AFTER'

          event_match = sql.match(/\b(INSERT|UPDATE|DELETE)\b/i)
          event = event_match ? event_match.captures.first.upcase : 'INSERT'

          {
            schema: 'main',
            name: row[0],
            table_name: row[1],
            timing: timing,
            event: event,
            statement: sql
          }
        end
      end

      # Capability methods - SQLite feature support

      def supports_extensions?
        false
      end

      def supports_materialized_views?
        false
      end

      def supports_custom_types?
        false
      end

      def supports_domains?
        false
      end

      def supports_functions?
        false # No stored procedures/functions
      end

      def supports_triggers?
        true
      end

      def supports_sequences?
        false # Uses AUTOINCREMENT instead
      end

      def supports_check_constraints?
        true # SQLite has always supported CHECK constraints
      end

      # Version detection

      def database_version
        @database_version ||= begin
          version_string = connection.select_value('SELECT sqlite_version()')
          parse_version(version_string)
        end
      end

      def parse_version(version_string)
        # Example: "3.45.1"
        match = version_string.match(/(\d+\.\d+\.\d+)/)
        return 'unknown' unless match

        match[1]
      end

      private

      # Helper methods for introspection

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

        connection.execute(query).pluck(0)
      end

      def fetch_columns(connection, table_name)
        table_info = connection.execute("PRAGMA table_info(#{connection.quote(table_name)})")

        table_info.map do |row|
          {
            name: row[1],
            type: resolve_column_type(row[2]),
            nullable: row[3].to_i.zero?,
            default: row[4],
            primary_key: row[5].to_i == 1
          }
        end
      end

      def fetch_primary_key(connection, table_name)
        table_info = connection.execute("PRAGMA table_info(#{connection.quote(table_name)})")

        table_info
          .select { |row| row[5].to_i == 1 }
          .sort_by { |row| row[5] } # Sort by pk order
          .pluck(1)
      end

      def fetch_constraints(connection, table_name)
        # SQLite stores CHECK constraints in the table SQL
        # Parse from sqlite_master
        query = <<~SQL.squish
          SELECT sql
          FROM sqlite_master
          WHERE type = 'table'
            AND name = #{connection.quote(table_name)}
        SQL

        result = connection.execute(query).first
        return [] unless result

        sql = result[0]
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
    end
  end
end
