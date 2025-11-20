# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE DOMAIN statements for custom types with constraints
    class DomainGenerator < Base
      # Generates CREATE DOMAIN statement
      #
      # @param domain [Hash] Domain metadata
      # @return [String] SQL statement
      def generate(domain)
        schema_prefix = domain[:schema] == 'public' ? '' : "#{domain[:schema]}."

        # Note: PostgreSQL does not support IF NOT EXISTS for domains
        parts = ["CREATE DOMAIN #{schema_prefix}#{domain[:name]} AS #{domain[:base_type]}"]

        parts << domain[:constraint] if domain[:constraint].present?

        "#{parts.join(' ')};"
      end
    end
  end
end
