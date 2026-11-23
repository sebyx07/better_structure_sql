# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE INDEX statements
    #
    # Supports unique indexes, partial indexes, and expression indexes.
    class IndexGenerator < Base
      # Generates CREATE INDEX statement
      #
      # @param index [Hash] Index metadata
      # @return [String] SQL statement
      def generate(index)
        # PostgreSQL provides complete definition via pg_indexes
        if index[:definition]
          definition = index[:definition]
          return definition.end_with?(';') ? definition : "#{definition};"
        end

        # For MySQL/SQLite, generate CREATE INDEX statement from components
        unique_clause = index[:unique] ? 'UNIQUE ' : ''
        columns_list = Array(index[:columns]).map { |col| quote_identifier(col) }.join(', ')
        table = quote_identifier(index[:table])
        name = quote_identifier(index[:name])

        # MySQL doesn't support IF NOT EXISTS for indexes, SQLite does
        # For simplicity, omit IF NOT EXISTS for cross-database compatibility
        "CREATE #{unique_clause}INDEX #{name} ON #{table} (#{columns_list});"
      end
    end
  end
end
