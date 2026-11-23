# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Generates CREATE TYPE statements for enums, composite and range types
    class TypeGenerator < Base
      # Generates CREATE TYPE statement
      #
      # @param type [Hash] Type metadata (enum, composite, range or domain)
      # @return [String, nil] SQL statement or nil if unsupported
      def generate(type)
        case type[:type]
        when 'enum'
          generate_enum(type)
        when 'composite'
          generate_composite(type)
        when 'range'
          generate_range(type)
        when 'domain'
          DomainGenerator.new(config).generate(type)
        else
          # Unknown type, skip
          nil
        end
      end

      private

      def generate_enum(type)
        values = type[:values].map { |value| quote_literal(value) }.join(', ')
        "CREATE TYPE #{type_name(type)} AS ENUM (#{values});"
      end

      def generate_composite(type)
        # NOTE: PostgreSQL does not support IF NOT EXISTS for composite types
        attrs = type[:attributes].map do |attr|
          "#{quote_identifier(attr[:name])} #{attr[:type]}"
        end.join(', ')
        "CREATE TYPE #{type_name(type)} AS (#{attrs});"
      end

      def generate_range(type)
        options = ["SUBTYPE = #{type[:subtype]}"]
        options << "SUBTYPE_OPCLASS = #{type[:subtype_opclass]}" if type[:subtype_opclass]
        options << "COLLATION = #{type[:collation]}" if type[:collation]
        options << "CANONICAL = #{type[:canonical]}" if type[:canonical]
        options << "SUBTYPE_DIFF = #{type[:subtype_diff]}" if type[:subtype_diff]
        "CREATE TYPE #{type_name(type)} AS RANGE (#{options.join(', ')});"
      end

      def type_name(type)
        qualified_identifier(type[:schema], type[:name])
      end

      def quote_literal(value)
        "'#{value.gsub("'", "''")}'"
      end
    end
  end
end
