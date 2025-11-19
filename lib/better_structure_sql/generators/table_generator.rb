# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class TableGenerator < Base
      attr_reader :adapter

      def initialize(config, adapter = nil)
        super(config)
        @adapter = adapter
      end

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

        # For SQLite, add foreign keys inline
        if sqlite_adapter? && table[:foreign_keys]&.any?
          table[:foreign_keys].each do |fk|
            column_defs << foreign_key_definition(fk)
          end
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

      def sqlite_adapter?
        adapter && adapter.class.name == 'BetterStructureSql::Adapters::SqliteAdapter'
      end

      def foreign_key_definition(fk)
        parts = ["FOREIGN KEY (#{fk[:column]})"]
        parts << "REFERENCES #{fk[:foreign_table]} (#{fk[:foreign_column]})"
        parts << "ON DELETE #{fk[:on_delete]}" if fk[:on_delete] && fk[:on_delete] != 'NO ACTION'
        parts << "ON UPDATE #{fk[:on_update]}" if fk[:on_update] && fk[:on_update] != 'NO ACTION'

        parts.join(' ')
      end
    end
  end
end
