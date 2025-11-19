# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class ExtensionGenerator < Base
      def generate(extension)
        # Quote extension name if it contains special characters
        ext_name = extension[:name].include?('-') ? "\"#{extension[:name]}\"" : extension[:name]
        schema_clause = extension[:schema] == 'public' ? '' : " WITH SCHEMA #{extension[:schema]}"
        "CREATE EXTENSION IF NOT EXISTS #{ext_name}#{schema_clause};"
      end
    end
  end
end
