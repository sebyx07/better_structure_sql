# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE MATERIALIZED VIEW statements for PostgreSQL
    class MaterializedViewGenerator < Base
      # Generates CREATE MATERIALIZED VIEW statement
      #
      # @param matview [Hash] Materialized view metadata
      # @return [String] SQL statement
      def generate(matview)
        definition = matview[:definition].strip

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        output = ["CREATE MATERIALIZED VIEW IF NOT EXISTS #{qualified_identifier(matview[:schema], matview[:name])} AS"]
        output << definition

        # Add indexes if present
        if matview[:indexes]&.any?
          output << ''
          output += matview[:indexes].map { |idx| "#{idx};" }
        end

        output << comment_statement(matview) if matview[:comment] && config.include_comments

        output.join("\n")
      end

      private

      # COMMENT ON MATERIALIZED VIEW statement
      #
      # The comments section only covers tables, columns, indexes, views and
      # functions, so materialized view comments are emitted with the view.
      #
      # @param matview [Hash] Materialized view metadata with :comment
      # @return [String] SQL statement
      def comment_statement(matview)
        name = qualified_identifier(matview[:schema], matview[:name])
        "COMMENT ON MATERIALIZED VIEW #{name} IS '#{matview[:comment].gsub("'", "''")}';"
      end
    end
  end
end
