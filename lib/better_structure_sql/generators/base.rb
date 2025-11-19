# frozen_string_literal: true

module BetterStructureSql
  module Generators
    class Base
      attr_reader :config

      def initialize(config = BetterStructureSql.configuration)
        @config = config
      end

      def generate(object)
        raise NotImplementedError, 'Subclasses must implement #generate'
      end

      private

      def indent(text, level = 1)
        spaces = ' ' * (config.indent_size * level)
        text.split("\n").map { |line| "#{spaces}#{line}" }.join("\n")
      end
    end
  end
end
