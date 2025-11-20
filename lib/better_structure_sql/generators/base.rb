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

      # Indent text by specified level
      #
      # @param text [String] Text to indent
      # @param level [Integer] Indentation level (default: 1)
      # @return [String] Indented text
      def indent(text, level = 1)
        spaces = ' ' * (config.indent_size * level)
        text.split("\n").map { |line| "#{spaces}#{line}" }.join("\n")
      end

      # Quote identifier based on database adapter
      #
      # @param identifier [String] Database identifier (table, column, index name)
      # @return [String] Quoted identifier
      def quote_identifier(identifier)
        return identifier if identifier.nil?

        adapter_name = detect_adapter_name

        if mysql_adapter?(adapter_name)
          "`#{identifier}`"
        else
          "\"#{identifier}\""
        end
      end

      # Detect current adapter name
      #
      # @return [String, nil] Adapter name or nil
      def detect_adapter_name
        ActiveRecord::Base.connection.adapter_name.downcase
      rescue StandardError
        nil
      end

      # Check if adapter is MySQL
      #
      # @param adapter_name [String, nil] Adapter name
      # @return [Boolean] True if MySQL adapter
      def mysql_adapter?(adapter_name)
        %w[mysql mysql2 trilogy].include?(adapter_name)
      end
    end
  end
end
