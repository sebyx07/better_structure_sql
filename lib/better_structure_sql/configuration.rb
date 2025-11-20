# frozen_string_literal: true

module BetterStructureSql
  # Configuration management for BetterStructureSql
  #
  # Provides centralized settings for dump behavior, feature toggles,
  # file output options, and schema versioning settings.
  class Configuration
    attr_accessor :search_path,
                  :replace_default_dump,
                  :replace_default_load,
                  :include_extensions,
                  :include_functions,
                  :include_triggers,
                  :include_views,
                  :include_materialized_views,
                  :include_rules,      # TODO: Not yet implemented
                  :include_comments,   # TODO: Not yet implemented
                  :include_domains,
                  :include_sequences,
                  :include_custom_types,
                  :enable_schema_versions,
                  :schema_versions_limit,
                  :schemas,
                  :indent_size,
                  :add_section_spacing,
                  :sort_tables,
                  :max_lines_per_file,
                  :overflow_threshold,
                  :generate_manifest,
                  :adapter

    attr_reader :output_path, :postgresql

    # Sets the output path for schema dump
    #
    # @param value [String, Pathname] Path to output file or directory
    # @return [String] The configured path as a string
    def output_path=(value)
      @output_path = value.to_s
    end

    def initialize
      @output_path = 'db/structure.sql'
      @search_path = '"$user", public'
      @replace_default_dump = false
      @replace_default_load = false
      @include_extensions = true
      @include_functions = true
      @include_triggers = true
      @include_views = true
      @include_materialized_views = true
      @include_rules = false
      @include_comments = false
      @include_domains = true
      @include_sequences = true
      @include_custom_types = true
      @enable_schema_versions = false
      @schema_versions_limit = 10
      @schemas = ['public']
      @indent_size = 2
      @add_section_spacing = true
      @sort_tables = true
      @max_lines_per_file = 500
      @overflow_threshold = 1.1
      @generate_manifest = true
      @adapter = :auto
      @postgresql = Adapters::PostgresqlConfig.new
    end

    # Validates configuration settings
    #
    # @raise [Error] If any configuration setting is invalid
    # @return [void]
    def validate!
      validate_output_path!
      validate_schema_versions_limit!
      validate_indent_size!
      validate_schemas!
      validate_max_lines_per_file!
      validate_overflow_threshold!
      validate_adapter!
    end

    private

    def validate_output_path!
      return unless output_path.nil? || output_path.strip.empty?

      raise ConfigurationError, 'output_path cannot be blank. Use absolute path or relative like "db/structure.sql"'
    end

    def validate_schema_versions_limit!
      return if schema_versions_limit.is_a?(Integer) && schema_versions_limit >= 0

      raise ConfigurationError, 'schema_versions_limit must be a non-negative integer (0 for unlimited, or positive number)'
    end

    def validate_indent_size!
      return if indent_size.is_a?(Integer) && indent_size.positive?

      raise ConfigurationError, 'indent_size must be a positive integer (typically 2 or 4)'
    end

    def validate_schemas!
      return if schemas.is_a?(Array) && schemas.any?

      raise ConfigurationError, 'schemas must be a non-empty array (e.g., ["public"] for PostgreSQL)'
    end

    def validate_max_lines_per_file!
      return if max_lines_per_file.is_a?(Integer) && max_lines_per_file.positive?

      raise ConfigurationError, 'max_lines_per_file must be a positive integer (recommended: 500-1000)'
    end

    def validate_overflow_threshold!
      return if overflow_threshold.is_a?(Numeric) && overflow_threshold >= 1.0

      raise ConfigurationError, 'overflow_threshold must be >= 1.0 (typically 1.1 for 10% overflow)'
    end

    def validate_adapter!
      valid_adapters = %i[auto postgresql mysql sqlite]

      return if valid_adapters.include?(adapter)

      raise ConfigurationError, "Invalid adapter: #{adapter}. Valid options: #{valid_adapters.join(', ')}"
    end
  end
end
