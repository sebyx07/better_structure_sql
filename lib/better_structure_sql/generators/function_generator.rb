# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class FunctionGenerator < Base
      def generate(function)
        # PostgreSQL's pg_get_functiondef and MySQL's SHOW CREATE both return
        # complete CREATE FUNCTION/PROCEDURE statements
        definition = function[:definition].strip

        # For MySQL, strip DEFINER clause which causes permission issues
        # and can't be loaded via ActiveRecord (would need mysql CLI with DELIMITER support)
        if definition.include?('CREATE DEFINER')
          # Remove DEFINER clause: "CREATE DEFINER=`user`@`host` PROCEDURE" -> "CREATE PROCEDURE"
          definition = definition.gsub(/CREATE DEFINER=`[^`]+`@`[^`]+`/, 'CREATE')
        end

        # Ensure definition ends with semicolon
        definition += ';' unless definition.end_with?(';')

        definition
      end
    end
  end
end
