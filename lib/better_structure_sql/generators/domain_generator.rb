# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE DOMAIN statements for custom types with constraints
    class DomainGenerator < Base
      # Generates CREATE DOMAIN statement
      #
      # @param domain [Hash] Domain metadata with :name, :schema, :base_type and
      #   optional :default, :not_null and :constraints (array of :name, :definition)
      # @return [String] SQL statement
      def generate(domain)
        # NOTE: PostgreSQL does not support IF NOT EXISTS for domains
        parts = ["CREATE DOMAIN #{qualified_identifier(domain[:schema], domain[:name])} AS #{domain[:base_type]}"]
        parts << "DEFAULT #{domain[:default]}" if domain[:default]
        parts << 'NOT NULL' if domain[:not_null]
        Array(domain[:constraints]).each do |constraint|
          parts << "CONSTRAINT #{quote_identifier(constraint[:name])} #{constraint[:definition]}"
        end

        "#{parts.join(' ')};"
      end
    end
  end
end
