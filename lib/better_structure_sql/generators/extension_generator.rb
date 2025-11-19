# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE EXTENSION statements for PostgreSQL
    class ExtensionGenerator < Base
      # Generates CREATE EXTENSION or PRAGMA statement
      #
      # @param extension [Hash] Extension metadata
      # @return [String] SQL statement
      def generate(extension)
        # Handle SQLite PRAGMAs (which are stored as "extensions")
        return extension[:sql] if extension[:sql]

        # PostgreSQL extensions
        # Quote extension name if it contains special characters
        ext_name = extension[:name].include?('-') ? "\"#{extension[:name]}\"" : extension[:name]
        schema_clause = extension[:schema] == 'public' ? '' : " WITH SCHEMA #{extension[:schema]}"
        "CREATE EXTENSION IF NOT EXISTS #{ext_name}#{schema_clause};"
      end
    end
  end
end
