# frozen_string_literal: true

# Configure BetterStructureSql for SQLite
BetterStructureSql.configure do |config|
  # Output paths
  config.output_path = 'db/structure.sql'

  # SQLite-specific settings
  config.adapter_override = :sqlite

  # Feature toggles (SQLite limitations)
  config.include_extensions = false # SQLite doesn't support extensions
  config.include_views = true
  config.include_functions = false # SQLite doesn't support stored procedures/functions
  config.include_triggers = true

  # Schema versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails schema dump
  config.replace_default_dump = true
end
