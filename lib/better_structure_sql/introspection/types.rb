# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Types
      def fetch_custom_types(connection)
        query = <<~SQL.squish
          SELECT
            t.typname as name,
            t.typtype as type,
            n.nspname as schema
          FROM pg_type t
          JOIN pg_namespace n ON n.oid = t.typnamespace
          LEFT JOIN pg_class c ON c.reltype = t.oid AND c.relkind IN ('r', 'v', 'm')
          WHERE t.typtype IN ('e', 'c', 'd')
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
            AND c.oid IS NULL
          ORDER BY t.typname
        SQL

        connection.execute(query).map do |row|
          type_data = {
            name: row['schema'] == 'public' ? row['name'] : "#{row['schema']}.#{row['name']}",
            schema: row['schema'],
            type: type_category(row['type'])
          }

          case row['type']
          when 'e'
            type_data[:values] = fetch_enum_values(connection, row['name'])
          when 'c'
            type_data[:attributes] = fetch_composite_attributes(connection, row['name'])
          when 'd'
            type_data.merge!(fetch_domain_details(connection, row['name']))
          end

          type_data
        end
      end

      def fetch_enums(connection)
        fetch_custom_types(connection).select { |t| t[:type] == 'enum' }
      end

      private

      def fetch_enum_values(connection, type_name)
        query = <<~SQL.squish
          SELECT e.enumlabel
          FROM pg_enum e
          JOIN pg_type t ON t.oid = e.enumtypid
          WHERE t.typname = $1
          ORDER BY e.enumsortorder
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).pluck('enumlabel')
      end

      def fetch_composite_attributes(connection, type_name)
        query = <<~SQL.squish
          SELECT
            a.attname as name,
            format_type(a.atttypid, a.atttypmod) as type
          FROM pg_attribute a
          JOIN pg_type t ON t.typrelid = a.attrelid
          WHERE t.typname = $1
            AND a.attnum > 0
            AND NOT a.attisdropped
          ORDER BY a.attnum
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).map do |row|
          { name: row['name'], type: row['type'] }
        end
      end

      def fetch_domain_details(connection, type_name)
        query = <<~SQL.squish
          SELECT
            format_type(t.typbasetype, t.typtypmod) as base_type,
            pg_get_constraintdef(c.oid) as constraint
          FROM pg_type t
          LEFT JOIN pg_constraint c ON c.contypid = t.oid
          WHERE t.typname = $1
        SQL

        result = connection.select_all(
          query.gsub('$1', connection.quote(type_name))
        ).first
        {
          base_type: result['base_type'],
          constraint: result['constraint']
        }
      end

      def type_category(type_code)
        case type_code
        when 'e' then 'enum'
        when 'c' then 'composite'
        when 'd' then 'domain'
        else 'unknown'
        end
      end
    end
  end
end
