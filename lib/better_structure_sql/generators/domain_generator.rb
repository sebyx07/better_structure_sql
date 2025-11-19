# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class DomainGenerator < Base
      def generate(domain)
        schema_prefix = domain[:schema] == 'public' ? '' : "#{domain[:schema]}."

        parts = ["CREATE DOMAIN #{schema_prefix}#{domain[:name]} AS #{domain[:base_type]}"]

        parts << domain[:constraint] if domain[:constraint].present?

        "#{parts.join(' ')};"
      end
    end
  end
end
