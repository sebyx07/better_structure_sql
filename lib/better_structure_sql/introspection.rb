module BetterStructureSql
  module Introspection
    class << self
      def fetch_extensions(connection)
        query = <<~SQL
          SELECT extname, extversion, nspname as schema_name
          FROM pg_extension
          JOIN pg_namespace ON pg_namespace.oid = pg_extension.extnamespace
          WHERE nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY extname
        SQL

        connection.execute(query).map do |row|
          {
            name: row["extname"],
            version: row["extversion"],
            schema: row["schema_name"]
          }
        end
      end

      def fetch_tables(connection)
        query = <<~SQL
          SELECT table_name, table_schema
          FROM information_schema.tables
          WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            AND table_type = 'BASE TABLE'
          ORDER BY table_name
        SQL

        connection.execute(query).map do |row|
          table_name = row["table_name"]
          {
            name: table_name,
            schema: row["table_schema"],
            columns: fetch_columns(connection, table_name),
            primary_key: fetch_primary_key(connection, table_name),
            constraints: fetch_constraints(connection, table_name)
          }
        end
      end

      def fetch_columns(connection, table_name)
        query = <<~SQL
          SELECT
            column_name,
            data_type,
            column_default,
            is_nullable,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            udt_name
          FROM information_schema.columns
          WHERE table_name = $1
            AND table_schema = 'public'
          ORDER BY ordinal_position
        SQL

        connection.exec_query(query, "SQL", [[nil, table_name]]).map do |row|
          {
            name: row["column_name"],
            type: resolve_column_type(row),
            default: row["column_default"],
            nullable: row["is_nullable"] == "YES",
            length: row["character_maximum_length"],
            precision: row["numeric_precision"],
            scale: row["numeric_scale"]
          }
        end
      end

      def fetch_primary_key(connection, table_name)
        query = <<~SQL
          SELECT a.attname as column_name
          FROM pg_index i
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          WHERE i.indrelid = $1::regclass
            AND i.indisprimary
          ORDER BY a.attnum
        SQL

        result = connection.exec_query(query, "SQL", [[nil, table_name]])
        result.map { |row| row["column_name"] }
      end

      def fetch_constraints(connection, table_name)
        query = <<~SQL
          SELECT
            conname as name,
            pg_get_constraintdef(oid) as definition,
            contype as type
          FROM pg_constraint
          WHERE conrelid = $1::regclass
            AND contype IN ('c', 'u')
          ORDER BY conname
        SQL

        connection.exec_query(query, "SQL", [[nil, table_name]]).map do |row|
          {
            name: row["name"],
            definition: row["definition"],
            type: constraint_type(row["type"])
          }
        end
      end

      def fetch_indexes(connection)
        query = <<~SQL
          SELECT
            schemaname,
            tablename,
            indexname,
            indexdef
          FROM pg_indexes
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY tablename, indexname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row["schemaname"],
            table: row["tablename"],
            name: row["indexname"],
            definition: row["indexdef"]
          }
        end.reject { |idx| idx[:name].end_with?("_pkey") }
      end

      def fetch_foreign_keys(connection)
        query = <<~SQL
          SELECT
            tc.table_name,
            tc.constraint_name,
            kcu.column_name,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name,
            rc.update_rule,
            rc.delete_rule
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
          JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
            AND rc.constraint_schema = tc.table_schema
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
          ORDER BY tc.table_name, tc.constraint_name
        SQL

        connection.execute(query).map do |row|
          {
            table: row["table_name"],
            name: row["constraint_name"],
            column: row["column_name"],
            foreign_table: row["foreign_table_name"],
            foreign_column: row["foreign_column_name"],
            on_update: row["update_rule"],
            on_delete: row["delete_rule"]
          }
        end
      end

      def fetch_sequences(connection)
        query = <<~SQL
          SELECT sequencename, schemaname
          FROM pg_sequences
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY sequencename
        SQL

        connection.execute(query).map do |row|
          {
            name: row["sequencename"],
            schema: row["schemaname"]
          }
        end
      end

      private

      def resolve_column_type(row)
        case row["data_type"]
        when "character varying"
          row["character_maximum_length"] ? "varchar(#{row['character_maximum_length']})" : "varchar"
        when "character"
          row["character_maximum_length"] ? "char(#{row['character_maximum_length']})" : "char"
        when "numeric"
          if row["numeric_precision"] && row["numeric_scale"]
            "numeric(#{row['numeric_precision']},#{row['numeric_scale']})"
          else
            "numeric"
          end
        when "timestamp without time zone"
          "timestamp"
        when "timestamp with time zone"
          "timestamptz"
        when "time without time zone"
          "time"
        when "USER-DEFINED"
          row["udt_name"]
        else
          row["data_type"]
        end
      end

      def constraint_type(type_code)
        case type_code
        when "c" then :check
        when "u" then :unique
        else :unknown
        end
      end
    end
  end
end
