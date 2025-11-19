# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Extensions
      def fetch_extensions(connection)
        query = <<~SQL.squish
          SELECT extname, extversion, nspname as schema_name
          FROM pg_extension
          JOIN pg_namespace ON pg_namespace.oid = pg_extension.extnamespace
          WHERE nspname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY extname
        SQL

        connection.execute(query).map do |row|
          {
            name: row['extname'],
            version: row['extversion'],
            schema: row['schema_name']
          }
        end
      end
    end
  end
end
