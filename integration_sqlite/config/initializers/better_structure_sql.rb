# frozen_string_literal: true

# Configure BetterStructureSql for SQLite
BetterStructureSql.configure do |config|
  # Output paths
  config.output_path = 'db/structure' # Multi-file directory output

  # Feature toggles (SQLite limitations)
  config.include_extensions = true # Include PRAGMA settings as "extensions"
  config.include_views = true
  config.include_functions = false # SQLite doesn't support stored procedures/functions
  config.include_triggers = true
  config.include_materialized_views = false # SQLite doesn't support materialized views
  config.include_sequences = false # SQLite uses AUTOINCREMENT
  config.include_domains = false # SQLite doesn't support domains
  config.include_custom_types = false # SQLite doesn't support custom types

  # Schema versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails schema dump and load (opt-in, default: false)
  # When false, use explicit tasks: rails db:schema:dump_better and rails db:schema:load_better
  config.replace_default_dump = false
  config.replace_default_load = false
end
