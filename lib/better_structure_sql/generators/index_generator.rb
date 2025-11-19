# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class IndexGenerator < Base
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

        "CREATE #{unique_clause}INDEX #{name} ON #{table} (#{columns_list});"
      end

      private

      def quote_identifier(identifier)
        return identifier if identifier.nil?

        # Detect adapter from ActiveRecord connection
        adapter_name = begin
          ActiveRecord::Base.connection.adapter_name.downcase
        rescue StandardError
          nil
        end

        # MySQL/MariaDB use backticks, PostgreSQL/SQLite use double quotes
        if %w[mysql mysql2 trilogy].include?(adapter_name)
          "`#{identifier}`"
        else
          "\"#{identifier}\""
        end
      end
    end
  end
end
