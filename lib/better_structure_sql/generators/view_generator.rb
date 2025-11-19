module BetterStructureSql
  module Generators
    class ViewGenerator < Base
      def generate(view)
        schema_prefix = view[:schema] == "public" ? "" : "#{view[:schema]}."
        definition = view[:definition].strip

        # Ensure definition ends with semicolon
        definition += ";" unless definition.end_with?(";")

        "CREATE VIEW #{schema_prefix}#{view[:name]} AS\n#{definition}"
      end
    end
  end
end
