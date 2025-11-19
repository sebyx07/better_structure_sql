# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class FunctionGenerator < Base
      def generate(function)
        # PostgreSQL's pg_get_functiondef returns complete CREATE FUNCTION statement
        definition = function[:definition].strip

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        definition
      end
    end
  end
end
