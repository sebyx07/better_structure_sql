module BetterStructureSql
  module Generators
    class DomainGenerator < Base
      def generate(domain)
        schema_prefix = domain[:schema] == "public" ? "" : "#{domain[:schema]}."

        parts = ["CREATE DOMAIN #{schema_prefix}#{domain[:name]} AS #{domain[:base_type]}"]

        if domain[:constraint] && !domain[:constraint].empty?
          parts << domain[:constraint]
        end

        "#{parts.join(' ')};"
      end
    end
  end
end
