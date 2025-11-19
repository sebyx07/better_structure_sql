# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class ExtensionGenerator < Base
      def generate(extension)
        schema_clause = extension[:schema] == 'public' ? '' : " WITH SCHEMA #{extension[:schema]}"
        "CREATE EXTENSION IF NOT EXISTS #{extension[:name]}#{schema_clause};"
      end
    end
  end
end
