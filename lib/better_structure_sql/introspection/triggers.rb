# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Triggers
      def fetch_triggers(connection)
        query = <<~SQL.squish
          SELECT
            n.nspname as schema,
            t.tgname as name,
            c.relname as table_name,
            pg_get_triggerdef(t.oid) as definition
          FROM pg_trigger t
          JOIN pg_class c ON c.oid = t.tgrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE NOT t.tgisinternal
            AND n.nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY c.relname, t.tgname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schema'],
            name: row['name'],
            table_name: row['table_name'],
            definition: row['definition']
          }
        end
      end
    end
  end
end
