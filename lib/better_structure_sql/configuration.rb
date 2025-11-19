module BetterStructureSql
  class Configuration
    attr_accessor :output_path,
                  :search_path,
                  :replace_default_dump,
                  :include_extensions,
                  :include_functions,
                  :include_triggers,
                  :include_views,
                  :enable_schema_versions,
                  :schema_versions_limit,
                  :indent_size,
                  :add_section_spacing,
                  :sort_tables

    def initialize
      @output_path = "db/structure.sql"
      @search_path = '"$user", public'
      @replace_default_dump = false
      @include_extensions = true
      @include_functions = false
      @include_triggers = false
      @include_views = false
      @enable_schema_versions = false
      @schema_versions_limit = 10
      @indent_size = 2
      @add_section_spacing = true
      @sort_tables = true
    end

    def validate!
      validate_output_path!
      validate_schema_versions_limit!
      validate_indent_size!
    end

    private

    def validate_output_path!
      raise Error, "output_path cannot be blank" if output_path.nil? || output_path.strip.empty?
    end

    def validate_schema_versions_limit!
      unless schema_versions_limit.is_a?(Integer) && schema_versions_limit >= 0
        raise Error, "schema_versions_limit must be a non-negative integer"
      end
    end

    def validate_indent_size!
      unless indent_size.is_a?(Integer) && indent_size > 0
        raise Error, "indent_size must be a positive integer"
      end
    end
  end
end
