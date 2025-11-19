# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE TABLE statements with columns and constraints
    #
    # Handles column definitions, primary keys, constraints, and
    # inline foreign keys for SQLite.
    class TableGenerator < Base
      attr_reader :adapter

      def initialize(config, adapter = nil)
        super(config)
        @adapter = adapter
      end

      # Generates CREATE TABLE statement
      #
      # @param table [Hash] Table metadata with columns and constraints
      # @return [String] SQL statement
      def generate(table)
        lines = ["CREATE TABLE IF NOT EXISTS #{table[:name]} ("]

        column_defs = table[:columns].map { |col| column_definition(col) }

        if table[:primary_key]&.any?
          # Quote primary key column names
          pk_cols = table[:primary_key].map { |col| quote_column_name(col) }.join(', ')
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
        # Quote column name for MySQL compatibility (reserved words like 'key')
        column_name = quote_column_name(column[:name])
        parts = [column_name, column[:type]]

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
        adapter&.class&.name == 'BetterStructureSql::Adapters::SqliteAdapter'
      end

      def foreign_key_definition(foreign_key)
        parts = ["FOREIGN KEY (#{foreign_key[:column]})"]
        parts << "REFERENCES #{foreign_key[:foreign_table]} (#{foreign_key[:foreign_column]})"
        parts << "ON DELETE #{foreign_key[:on_delete]}" if foreign_key[:on_delete] && foreign_key[:on_delete] != 'NO ACTION'
        parts << "ON UPDATE #{foreign_key[:on_update]}" if foreign_key[:on_update] && foreign_key[:on_update] != 'NO ACTION'

        parts.join(' ')
      end

      def quote_column_name(column_name)
        # Detect adapter from ActiveRecord connection
        adapter_name = begin
          ActiveRecord::Base.connection.adapter_name.downcase
        rescue StandardError
          nil
        end

        # MySQL/MariaDB use backticks, PostgreSQL/SQLite use double quotes
        if %w[mysql mysql2 trilogy].include?(adapter_name)
          "`#{column_name}`"
        else
          "\"#{column_name}\""
        end
      end
    end
  end
end
