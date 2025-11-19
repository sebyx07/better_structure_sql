# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class TableGenerator < Base
      def generate(table)
        lines = ["CREATE TABLE #{table[:name]} ("]

        column_defs = table[:columns].map { |col| column_definition(col) }

        if table[:primary_key]&.any?
          pk_cols = table[:primary_key].join(', ')
          column_defs << "PRIMARY KEY (#{pk_cols})"
        end

        table[:constraints]&.each do |constraint|
          column_defs << constraint_definition(constraint)
        end

        lines << column_defs.map { |def_line| indent(def_line) }.join(",\n")
        lines << ');'

        lines.join("\n")
      end

      private

      def column_definition(column)
        parts = [column[:name], column[:type]]

        parts << 'NOT NULL' unless column[:nullable]

        if column[:default]
          default_value = format_default(column[:default])
          parts << "DEFAULT #{default_value}"
        end

        parts.join(' ')
      end

      def constraint_definition(constraint)
        case constraint[:type]
        when :check
        when :unique
        end
        "CONSTRAINT #{constraint[:name]} #{constraint[:definition]}"
      end

      def format_default(default_value)
        return default_value if default_value.nil?

        # Handle nextval for sequences
        return default_value if default_value.start_with?('nextval(')

        # Handle NULL
        return 'NULL' if default_value.upcase == 'NULL'

        # Handle boolean values
        return default_value if %w[true false].include?(default_value.downcase)

        # Handle numeric values
        return default_value if default_value.match?(/\A-?\d+(\.\d+)?\z/)

        # Handle functions and expressions
        return default_value if default_value.include?('(') || default_value.upcase.start_with?('CURRENT_')

        # Otherwise, assume it's a string and quote it if not already quoted
        default_value.start_with?("'") ? default_value : "'#{default_value}'"
      end
    end
  end
end
