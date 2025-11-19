# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class SequenceGenerator < Base
      def generate(sequence)
        parts = ["CREATE SEQUENCE #{sequence[:name]}"]

        parts << "START WITH #{sequence[:start_value]}" if sequence[:start_value]
        parts << "INCREMENT BY #{sequence[:increment]}" if sequence[:increment] && sequence[:increment] != 1
        parts << "MINVALUE #{sequence[:min_value]}" if sequence[:min_value]
        parts << "MAXVALUE #{sequence[:max_value]}" if sequence[:max_value]

        parts << "CACHE #{sequence[:cache_size]}" if sequence[:cache_size] && sequence[:cache_size] > 1

        parts << 'CYCLE' if sequence[:cycle]

        "#{parts.join("\n  ")};"
      end
    end
  end
end
