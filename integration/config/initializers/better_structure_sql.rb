# frozen_string_literal: true

# BetterStructureSql Configuration
#
# This file configures how BetterStructureSql generates schema dumps and manages versioning.
# All settings have sensible defaults and can be overridden via environment variables.
#
# For more configuration examples, see:
#   - docs/migration-guides/from-schema-rb-to-structure-sql.md
#   - docs/features/dev-environment-docker-web-ui/plan/phase-3.md

BetterStructureSql.configure do |config|
  # ===================================================================================
  # OUTPUT CONFIGURATION
  # ===================================================================================

  # Output path for schema dump
  # Automatically respects Rails schema_format configuration
  # Can be overridden via SCHEMA_FORMAT environment variable
  #
  # Examples:
  #   - db/structure.sql  (default for SQL format)
  #   - db/schema.rb      (for Ruby format)
  #   - custom/path.sql   (custom location)
  #
  # The format (SQL vs Ruby) is automatically detected from the file extension
  # For multi-file mode, set output_path to a directory (e.g., 'db/schema')
  schema_file = if Rails.application.config.active_record.schema_format == :ruby
                  'db/schema.rb'
                else
                  ENV.fetch('MULTI_FILE_SCHEMA', 'false') == 'true' ? 'db/schema' : 'db/structure.sql'
                end
  config.output_path = Rails.root.join(ENV.fetch('SCHEMA_OUTPUT_PATH', schema_file))

  # ===================================================================================
  # SCHEMA SEARCH PATH
  # ===================================================================================

  # PostgreSQL schema search path
  # Determines which schemas are included in the dump
  #
  # Examples:
  #   - 'public'                    (default - public schema only)
  #   - 'public, app_schema'        (multiple schemas)
  #   - '"$user", public'           (user schema first, then public)
  #
  config.search_path = ENV.fetch('SCHEMA_SEARCH_PATH', 'public')

  # ===================================================================================
  # POSTGRESQL FEATURE TOGGLES
  # ===================================================================================

  # Include PostgreSQL extensions (pgcrypto, uuid-ossp, etc.)
  # Recommended: true for PostgreSQL, false for other databases
  config.include_extensions = ENV.fetch('INCLUDE_EXTENSIONS', 'true') == 'true'

  # Include database views (both regular and materialized)
  # Set to false if you only want tables and don't use views
  config.include_views = ENV.fetch('INCLUDE_VIEWS', 'true') == 'true'

  # Include materialized views separately
  # Only applies if include_views is true
  config.include_materialized_views = ENV.fetch('INCLUDE_MATERIALIZED_VIEWS', 'true') == 'true'

  # Include custom functions (plpgsql, sql, etc.)
  # Set to false if you don't use stored procedures
  config.include_functions = ENV.fetch('INCLUDE_FUNCTIONS', 'true') == 'true'

  # Include triggers
  # Set to false if you don't use database triggers
  config.include_triggers = ENV.fetch('INCLUDE_TRIGGERS', 'true') == 'true'

  # Include custom domains and types
  # Set to false if you only use built-in types
  config.include_domains = ENV.fetch('INCLUDE_DOMAINS', 'true') == 'true'

  # Include comments on database objects
  # Set to true if you use COMMENT ON statements
  config.include_comments = ENV.fetch('INCLUDE_COMMENTS', 'false') == 'true'

  # ===================================================================================
  # SCHEMA VERSIONING
  # ===================================================================================

  # Enable schema version storage in database
  # When enabled, each dump can be stored as a version for history/comparison
  # Disabled in test environment as it's not needed
  config.enable_schema_versions = if Rails.env.test?
                                    false
                                  else
                                    ENV.fetch('ENABLE_SCHEMA_VERSIONS', 'true') == 'true'
                                  end

  # Schema version retention limit
  # How many versions to keep in the database
  #
  # Options:
  #   - 0       : Unlimited (keep all versions)
  #   - 10      : Keep last 10 versions (recommended default)
  #   - 5       : Keep last 5 versions (for limited storage)
  #   - 100     : Keep last 100 versions (for comprehensive history)
  #
  config.schema_versions_limit = ENV.fetch('SCHEMA_VERSIONS_LIMIT', '10').to_i

  # ===================================================================================
  # RAILS INTEGRATION (opt-in)
  # ===================================================================================

  # Replace default Rails schema dump task (opt-in, default: false)
  # When true, `rails db:schema:dump` uses BetterStructureSql instead of pg_dump
  # When false, use explicit task: `rails db:schema:dump_better`
  #
  # Set to false if you want to use both side-by-side
  config.replace_default_dump = ENV.fetch('REPLACE_DEFAULT_DUMP', 'false') == 'true'

  # Replace default Rails schema load task (opt-in, default: false)
  # When true, `rails db:schema:load` uses BetterStructureSql loader
  # When false, use explicit task: `rails db:schema:load_better`
  config.replace_default_load = ENV.fetch('REPLACE_DEFAULT_LOAD', 'false') == 'true'

  # ===================================================================================
  # FORMATTING OPTIONS
  # ===================================================================================

  # Indent size for generated SQL (spaces)
  # Standard is 2 spaces for readability
  config.indent_size = ENV.fetch('SCHEMA_INDENT_SIZE', '2').to_i

  # Add blank lines between sections for better readability
  # Recommended: true for human-readable output
  config.add_section_spacing = ENV.fetch('SECTION_SPACING', 'true') == 'true'

  # Sort tables alphabetically in output
  # Recommended: true for consistent diffs
  config.sort_tables = ENV.fetch('SORT_TABLES', 'true') == 'true'

  # ===================================================================================
  # ADVANCED OPTIONS
  # ===================================================================================

  # Schemas to include (array of schema names)
  # Default is ['public'], but you can add custom schemas
  #
  # Example: config.schemas = ['public', 'app_schema', 'audit']
  #
  # config.schemas = ENV.fetch('SCHEMAS', 'public').split(',').map(&:strip)

  # ===================================================================================
  # ENVIRONMENT-SPECIFIC CONFIGURATION EXAMPLE
  # ===================================================================================
  #
  # You can customize configuration based on Rails environment:
  #
  # if Rails.env.development?
  #   config.schema_versions_limit = 20  # Keep more versions in development
  # elsif Rails.env.test?
  #   config.include_views = false       # Skip views in test for faster schema loads
  # end

  # ===================================================================================
  # LOGGING
  # ===================================================================================

  # Log configuration on Rails startup (development only)
  if Rails.env.development? && defined?(Rails.logger)
    Rails.logger.info '[BetterStructureSql] Configuration loaded:'
    Rails.logger.info "  Output path: #{config.output_path}"
    Rails.logger.info "  Schema format: #{config.output_path.to_s.end_with?('.rb') ? 'Ruby' : 'SQL'}"
    Rails.logger.info "  Versioning enabled: #{config.enable_schema_versions}"
    Rails.logger.info "  Version limit: #{config.schema_versions_limit.zero? ? 'unlimited' : config.schema_versions_limit}"
    Rails.logger.info "  PostgreSQL features: extensions=#{config.include_extensions}, " \
                      "views=#{config.include_views}, functions=#{config.include_functions}, triggers=#{config.include_triggers}"
  end
end
