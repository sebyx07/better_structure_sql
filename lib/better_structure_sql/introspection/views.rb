# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Views
      def fetch_views(connection)
        query = <<~SQL.squish
          SELECT
            schemaname,
            viewname,
            definition
          FROM pg_views
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY viewname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            name: row['viewname'],
            definition: row['definition']
          }
        end
      end

      def fetch_materialized_views(connection)
        query = <<~SQL.squish
          SELECT
            schemaname,
            matviewname,
            definition
          FROM pg_matviews
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY matviewname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            name: row['matviewname'],
            definition: row['definition'],
            indexes: fetch_materialized_view_indexes(connection, row['matviewname'])
          }
        end
      end
    end
  end
end
