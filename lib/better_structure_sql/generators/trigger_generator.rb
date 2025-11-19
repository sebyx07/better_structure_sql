# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE TRIGGER statements
    #
    # Supports BEFORE, AFTER, INSTEAD OF triggers with row/statement timing.
    class TriggerGenerator < Base
      # Generates CREATE TRIGGER statement
      #
      # @param trigger [Hash] Trigger metadata
      # @return [String] SQL statement
      def generate(trigger)
        # PostgreSQL's pg_get_triggerdef returns complete CREATE TRIGGER statement
        # MySQL SHOW CREATE TRIGGER also returns complete statement
        if trigger[:definition]
          definition = trigger[:definition].strip

          # Strip DEFINER clause for MySQL triggers for portability
          definition = definition.gsub(/CREATE DEFINER=`[^`]+`@`[^`]+`/, 'CREATE') if definition.include?('CREATE DEFINER')

          # Ensure ends with semicolon for structure.sql
          definition += ';' unless definition.end_with?(';')
          return definition
        end

        # For MySQL/SQLite, generate CREATE TRIGGER from components
        timing = trigger[:timing] || 'AFTER'
        event = trigger[:event] || 'INSERT'
        table_name = quote_identifier(trigger[:table_name])
        trigger_name = quote_identifier(trigger[:name])
        statement = trigger[:statement] || trigger[:body] || ''

        <<~SQL.strip
          CREATE TRIGGER #{trigger_name}
          #{timing} #{event} ON #{table_name}
          FOR EACH ROW
          BEGIN
            #{statement}
          END;
        SQL
      end

      private

      def quote_identifier(identifier)
        return identifier if identifier.nil?

        # Use double quotes for SQL standard identifier quoting
        "\"#{identifier}\""
      end
    end
  end
end
