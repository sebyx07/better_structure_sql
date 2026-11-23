# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates ALTER TABLE ADD CONSTRAINT for foreign keys
    #
    # Handles CASCADE, RESTRICT, SET NULL actions.
    class ForeignKeyGenerator < Base
      # Generates ALTER TABLE ADD CONSTRAINT for foreign key
      #
      # PostgreSQL supplies the full constraint :definition (columns, MATCH,
      # actions, DEFERRABLE, NOT VALID); other adapters supply its components.
      #
      # @param foreign_key [Hash] Foreign key metadata
      # @return [String] SQL statement
      def generate(foreign_key)
        return generate_from_definition(foreign_key) if foreign_key[:definition]

        parts = [
          "ALTER TABLE #{quote_identifier(foreign_key[:table])}",
          "ADD CONSTRAINT #{quote_identifier(foreign_key[:name])}",
          "FOREIGN KEY (#{quote_identifier_list(foreign_key[:columns])})",
          "REFERENCES #{quote_identifier(foreign_key[:foreign_table])} (#{quote_identifier_list(foreign_key[:foreign_columns])})"
        ]

        on_delete = format_action(foreign_key[:on_delete])
        parts << "ON DELETE #{on_delete}" if on_delete != 'NO ACTION'

        on_update = format_action(foreign_key[:on_update])
        parts << "ON UPDATE #{on_update}" if on_update != 'NO ACTION'

        "#{parts.join(' ')};"
      end

      private

      def generate_from_definition(foreign_key)
        "ALTER TABLE #{quote_identifier(foreign_key[:table])} " \
          "ADD CONSTRAINT #{quote_identifier(foreign_key[:name])} #{foreign_key[:definition]};"
      end

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
