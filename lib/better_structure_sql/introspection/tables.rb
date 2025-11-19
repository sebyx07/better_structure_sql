# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Tables
      def fetch_tables(connection)
        query = <<~SQL.squish
          SELECT table_name, table_schema
          FROM information_schema.tables
          WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            AND table_type = 'BASE TABLE'
          ORDER BY table_name
        SQL

        connection.execute(query).map do |row|
          table_name = row['table_name']
          {
            name: table_name,
            schema: row['table_schema'],
            columns: fetch_columns(connection, table_name),
            primary_key: fetch_primary_key(connection, table_name),
            constraints: fetch_constraints(connection, table_name)
          }
        end
      end

      def fetch_columns(connection, table_name)
        query = <<~SQL.squish
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

        connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        ).map do |row|
          {
            name: row['column_name'],
            type: resolve_column_type(row),
            default: row['column_default'],
            nullable: row['is_nullable'] == 'YES',
            length: row['character_maximum_length'],
            precision: row['numeric_precision'],
            scale: row['numeric_scale']
          }
        end
      end

      def fetch_primary_key(connection, table_name)
        query = <<~SQL.squish
          SELECT a.attname as column_name
          FROM pg_index i
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          WHERE i.indrelid = $1::regclass
            AND i.indisprimary
          ORDER BY a.attnum
        SQL

        result = connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        )
        result.pluck('column_name')
      end

      def fetch_constraints(connection, table_name)
        query = <<~SQL.squish
          SELECT
            conname as name,
            pg_get_constraintdef(oid) as definition,
            contype as type
          FROM pg_constraint
          WHERE conrelid = $1::regclass
            AND contype IN ('c', 'u')
          ORDER BY conname
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(table_name))
        ).map do |row|
          {
            name: row['name'],
            definition: row['definition'],
            type: constraint_type(row['type'])
          }
        end
      end

      private

      def resolve_column_type(row)
        case row['data_type']
        when 'ARRAY'
          # For arrays, udt_name contains the base type with leading underscore (e.g., _varchar)
          base_type = row['udt_name'].sub(/^_/, '')
          "#{base_type}[]"
        when 'character varying'
          row['character_maximum_length'] ? "varchar(#{row['character_maximum_length']})" : 'varchar'
        when 'character'
          row['character_maximum_length'] ? "char(#{row['character_maximum_length']})" : 'char'
        when 'numeric'
          if row['numeric_precision'] && row['numeric_scale']
            "numeric(#{row['numeric_precision']},#{row['numeric_scale']})"
          else
            'numeric'
          end
        when 'timestamp without time zone'
          'timestamp'
        when 'timestamp with time zone'
          'timestamptz'
        when 'time without time zone'
          'time'
        when 'USER-DEFINED'
          row['udt_name']
        else
          row['data_type']
        end
      end

      def constraint_type(type_code)
        case type_code
        when 'c' then :check
        when 'u' then :unique
        else :unknown
        end
      end
    end
  end
end
