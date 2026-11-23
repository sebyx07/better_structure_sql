# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE SEQUENCE statements
    class SequenceGenerator < Base
      # Generates CREATE SEQUENCE statement
      #
      # @param sequence [Hash] Sequence metadata
      # @return [String] SQL statement
      def generate(sequence)
        parts = ["CREATE SEQUENCE IF NOT EXISTS #{quote_identifier(sequence[:name])}"]
        parts << "AS #{sequence[:data_type]}" if sequence[:data_type] && sequence[:data_type] != 'bigint'
        parts.concat(options(sequence))

        "#{parts.join("\n  ")};"
      end

      # Sequence option clauses shared by CREATE SEQUENCE and identity columns
      #
      # @param sequence [Hash] Sequence metadata
      # @return [Array<String>] Option clauses (e.g. "START WITH 1", "CYCLE")
      def options(sequence)
        parts = []
        parts << "START WITH #{sequence[:start_value]}" if sequence[:start_value]
        parts << "INCREMENT BY #{sequence[:increment]}" if sequence[:increment] && sequence[:increment] != 1
        parts << "MINVALUE #{sequence[:min_value]}" if sequence[:min_value]
        parts << "MAXVALUE #{sequence[:max_value]}" if sequence[:max_value]
        parts << "CACHE #{sequence[:cache_size]}" if sequence[:cache_size] && sequence[:cache_size] > 1
        parts << 'CYCLE' if sequence[:cycle]
        parts
      end
    end
  end
end
