# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class FunctionGenerator < Base
      def generate(function)
        # PostgreSQL's pg_get_functiondef and MySQL's SHOW CREATE both return
        # complete CREATE FUNCTION/PROCEDURE statements
        definition = function[:definition].strip

        # For MySQL, strip DEFINER clause which causes permission issues
        if definition.include?('CREATE DEFINER')
          # Remove DEFINER clause: "CREATE DEFINER=`user`@`host` PROCEDURE" -> "CREATE PROCEDURE"
          definition = definition.gsub(/CREATE DEFINER=`[^`]+`@`[^`]+`/, 'CREATE')
        end

        # For dumping to structure.sql, we need to ensure the statement ends with semicolon
        # MySQL SHOW CREATE PROCEDURE returns WITHOUT semicolon, so add it
        # PostgreSQL pg_get_functiondef includes it, so don't add duplicate
        definition += ';' unless definition.end_with?(';')

        definition
      end
    end
  end
end
