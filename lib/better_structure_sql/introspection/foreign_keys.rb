# frozen_string_literal: true

module BetterStructureSql
  module Introspection
    module ForeignKeys
      def fetch_foreign_keys(connection)
        query = <<~SQL.squish
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
            table: row['table_name'],
            name: row['constraint_name'],
            column: row['column_name'],
            foreign_table: row['foreign_table_name'],
            foreign_column: row['foreign_column_name'],
            on_update: row['update_rule'],
            on_delete: row['delete_rule']
          }
        end
      end
    end
  end
end
