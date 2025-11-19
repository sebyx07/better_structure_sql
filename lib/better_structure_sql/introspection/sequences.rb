# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module Sequences
      def fetch_sequences(connection)
        query = <<~SQL.squish
          SELECT
            sequencename,
            schemaname,
            start_value,
            increment_by,
            min_value,
            max_value,
            cache_size,
            cycle
          FROM pg_sequences
          WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
          ORDER BY sequencename
        SQL

        connection.execute(query).map do |row|
          {
            name: row['sequencename'],
            schema: row['schemaname'],
            start_value: row['start_value'],
            increment: row['increment_by'],
            min_value: row['min_value'],
            max_value: row['max_value'],
            cache_size: row['cache_size'],
            cycle: row['cycle']
          }
        end
      end
    end
  end
end
