module BetterStructureSql
  module Generators
    class IndexGenerator < Base
      def generate(index)
        # The indexdef from pg_indexes already contains the complete CREATE INDEX statement
        # We just need to ensure it ends with a semicolon
        definition = index[:definition]
        definition.end_with?(";") ? definition : "#{definition};"
      end
    end
  end
end
