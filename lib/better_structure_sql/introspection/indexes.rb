# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Indexes
      def fetch_indexes(connection)
        query = <<~SQL.squish
          SELECT
            pi.schemaname,
            pi.tablename,
            pi.indexname,
            pi.indexdef
          FROM pg_indexes pi
          LEFT JOIN pg_matviews mv ON mv.matviewname = pi.tablename AND mv.schemaname = pi.schemaname
          WHERE pi.schemaname NOT IN ('pg_catalog', 'information_schema')
            AND mv.matviewname IS NULL
          ORDER BY pi.tablename, pi.indexname
        SQL

        connection.execute(query).map do |row|
          {
            schema: row['schemaname'],
            table: row['tablename'],
            name: row['indexname'],
            definition: row['indexdef']
          }
        end.reject { |idx| idx[:name].end_with?('_pkey') }
      end

      def fetch_materialized_view_indexes(connection, matview_name)
        query = <<~SQL.squish
          SELECT indexdef
          FROM pg_indexes
          WHERE tablename = $1
          ORDER BY indexname
        SQL

        connection.select_all(
          query.gsub('$1', connection.quote(matview_name))
        ).pluck('indexdef')
      end
    end
  end
end
