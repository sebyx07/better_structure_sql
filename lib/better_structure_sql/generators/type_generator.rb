module BetterStructureSql
  module Generators
    class TypeGenerator < Base
      def generate(type)
        case type[:type]
        when "enum"
          generate_enum(type)
        when "composite"
          generate_composite(type)
        when "domain"
          generate_domain(type)
        else
          # Unknown type, skip
          nil
        end
      end

      private

      def generate_enum(type)
        values = type[:values].map { |v| "'#{v}'" }.join(", ")
        "CREATE TYPE #{type[:name]} AS ENUM (#{values});"
      end

      def generate_composite(type)
        # Composite types have attributes
        attrs = type[:attributes].map do |attr|
          "#{attr[:name]} #{attr[:type]}"
        end.join(", ")
        "CREATE TYPE #{type[:name]} AS (#{attrs});"
      end

      def generate_domain(type)
        parts = ["CREATE DOMAIN #{type[:name]} AS #{type[:base_type]}"]
        parts << type[:constraint] if type[:constraint]
        "#{parts.join(' ')};"
      end
    end
  end
end
