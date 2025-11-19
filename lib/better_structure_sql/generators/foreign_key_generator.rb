# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates ALTER TABLE ADD CONSTRAINT for foreign keys
    #
    # Handles CASCADE, RESTRICT, SET NULL actions.
    class ForeignKeyGenerator < Base
      # Generates ALTER TABLE ADD CONSTRAINT for foreign key
      #
      # @param foreign_key [Hash] Foreign key metadata
      # @return [String] SQL statement
      def generate(foreign_key)
        parts = [
          "ALTER TABLE #{foreign_key[:table]}",
          "ADD CONSTRAINT #{foreign_key[:name]}",
          "FOREIGN KEY (#{foreign_key[:column]})",
          "REFERENCES #{foreign_key[:foreign_table]} (#{foreign_key[:foreign_column]})"
        ]

        on_delete = format_action(foreign_key[:on_delete])
        parts << "ON DELETE #{on_delete}" if on_delete != 'NO ACTION'

        on_update = format_action(foreign_key[:on_update])
        parts << "ON UPDATE #{on_update}" if on_update != 'NO ACTION'

        "#{parts.join(' ')};"
      end

      private

      def format_action(action)
        case action&.upcase
        when 'CASCADE' then 'CASCADE'
        when 'SET NULL' then 'SET NULL'
        when 'SET DEFAULT' then 'SET DEFAULT'
        when 'RESTRICT' then 'RESTRICT'
        else 'NO ACTION'
        end
      end
    end
  end
end
