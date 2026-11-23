# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE EXTENSION statements for PostgreSQL
    class ExtensionGenerator < Base
      # Generates CREATE EXTENSION or PRAGMA statement
      #
      # Extensions installed outside 'public' also get a CREATE SCHEMA IF NOT EXISTS,
      # since WITH SCHEMA requires the schema to exist.
      #
      # @param extension [Hash] Extension metadata
      # @return [String] SQL statement
      def generate(extension)
        # Handle SQLite PRAGMAs (which are stored as "extensions")
        return extension[:sql] if extension[:sql]

        # PostgreSQL extensions
        # Quote extension name if it contains special characters
        ext_name = extension[:name].include?('-') ? "\"#{extension[:name]}\"" : extension[:name]
        return "CREATE EXTENSION IF NOT EXISTS #{ext_name};" if extension[:schema] == 'public'

        schema = quote_identifier(extension[:schema])
        "CREATE SCHEMA IF NOT EXISTS #{schema};\nCREATE EXTENSION IF NOT EXISTS #{ext_name} WITH SCHEMA #{schema};"
      end
    end
  end
end
