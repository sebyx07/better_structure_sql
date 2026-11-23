# frozen_string_literal: true

module BetterStructureSql
  module Generators
    # Base class for all SQL generators
    #
    # Provides common functionality for generating SQL statements
    # from database object metadata.
    class Base
      # Schemas whose objects are referenced without a schema prefix
      DEFAULT_SCHEMAS = %w[public main].freeze

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
      # @return [String] Quoted identifier, with embedded quote characters doubled
      def quote_identifier(identifier)
        return identifier if identifier.nil?

        adapter_name = detect_adapter_name

        if mysql_adapter?(adapter_name)
          "`#{identifier.to_s.gsub('`', '``')}`"
        else
          "\"#{identifier.to_s.gsub('"', '""')}\""
        end
      end

      # Quote a list of identifiers (e.g. the columns of a composite key)
      #
      # @param identifiers [Array<String>] Identifiers in order
      # @return [String] Comma-separated quoted identifiers
      def quote_identifier_list(identifiers)
        identifiers.map { |identifier| quote_identifier(identifier) }.join(', ')
      end

      # Quote a possibly schema-qualified identifier
      #
      # The schema is omitted for default schemas (PostgreSQL 'public', SQLite 'main').
      #
      # @param schema [String, nil] Schema name
      # @param name [String] Object name
      # @return [String] Quoted, optionally schema-qualified identifier
      def qualified_identifier(schema, name)
        return quote_identifier(name) if schema.nil? || DEFAULT_SCHEMAS.include?(schema)

        "#{quote_identifier(schema)}.#{quote_identifier(name)}"
      end

      # Detect current adapter name
      #
      # Without an established connection (generators used standalone) there is
      # no adapter to match, so identifiers get standard SQL double quotes.
      #
      # @return [String, nil] Adapter name or nil
      def detect_adapter_name
        ActiveRecord::Base.connection.adapter_name.downcase
      rescue ActiveRecord::ConnectionNotEstablished
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
