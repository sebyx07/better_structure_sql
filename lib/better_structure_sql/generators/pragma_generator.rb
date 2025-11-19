# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generator for SQLite PRAGMA statements
    # PRAGMAs returned by SqliteAdapter are in format:
    # { name: 'foreign_keys', value: 1, sql: 'PRAGMA foreign_keys = 1;' }
    class PragmaGenerator < Base
      def generate(pragma)
        # If SQL is pre-generated, use it
        return pragma[:sql] if pragma[:sql]

        # Otherwise generate from name and value
        "PRAGMA #{pragma[:name]} = #{pragma[:value]};"
      end
    end
  end
end
