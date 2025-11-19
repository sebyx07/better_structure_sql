# frozen_string_literal: true

module BetterStructureSql
  class Configuration
    attr_accessor :output_path,
                  :search_path,
                  :replace_default_dump,
                  :include_extensions,
                  :include_functions,
                  :include_triggers,
                  :include_views,
                  :include_materialized_views,
                  :include_rules,
                  :include_comments,
                  :include_domains,
                  :include_sequences,
                  :include_custom_types,
                  :enable_schema_versions,
                  :schema_versions_limit,
                  :schemas,
                  :indent_size,
                  :add_section_spacing,
                  :sort_tables

    def initialize
      @output_path = 'db/structure.sql'
      @search_path = '"$user", public'
      @replace_default_dump = false
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
    end

    def validate!
      validate_output_path!
      validate_schema_versions_limit!
      validate_indent_size!
      validate_schemas!
    end

    private

    def validate_output_path!
      raise Error, 'output_path cannot be blank' if output_path.nil? || output_path.strip.empty?
    end

    def validate_schema_versions_limit!
      return if schema_versions_limit.is_a?(Integer) && schema_versions_limit >= 0

      raise Error, 'schema_versions_limit must be a non-negative integer'
    end

    def validate_indent_size!
      return if indent_size.is_a?(Integer) && indent_size.positive?

      raise Error, 'indent_size must be a positive integer'
    end

    def validate_schemas!
      return if schemas.is_a?(Array) && schemas.any?

      raise Error, 'schemas must be a non-empty array'
    end
  end
end
