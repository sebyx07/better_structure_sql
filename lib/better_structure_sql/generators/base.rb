# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Base class for all SQL generators
    #
    # Provides common functionality for generating SQL statements
    # from database object metadata.
    class Base
      attr_reader :config

      def initialize(config = BetterStructureSql.configuration)
        @config = config
      end

      # Generates SQL for a database object
      #
      # @param object [Hash] Object metadata from introspection
      # @return [String] SQL statement
      # @raise [NotImplementedError] Must be implemented by subclasses
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
