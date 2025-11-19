# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class ViewGenerator < Base
      def generate(view)
        # Only add schema prefix for non-default schemas
        # PostgreSQL default: 'public'
        # SQLite default: 'main'
        # MySQL default: current database
        default_schemas = %w[public main]
        schema_prefix = default_schemas.include?(view[:schema]) ? '' : "#{view[:schema]}."
        definition = view[:definition].strip

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        "CREATE VIEW #{schema_prefix}#{view[:name]} AS\n#{definition}"
      end
    end
  end
end
