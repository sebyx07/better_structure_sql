# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class MaterializedViewGenerator < Base
      def generate(matview)
        schema_prefix = matview[:schema] == 'public' ? '' : "#{matview[:schema]}."
        definition = matview[:definition].strip

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        output = ["CREATE MATERIALIZED VIEW #{schema_prefix}#{matview[:name]} AS"]
        output << definition

        # Add indexes if present
        if matview[:indexes]&.any?
          output << ''
          output += matview[:indexes].map { |idx| "#{idx};" }
        end

        output.join("\n")
      end
    end
  end
end
