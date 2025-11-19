# frozen_string_literal: true

BetterStructureSql.configure do |config|
  # Output path for structure dump
  config.output_path = Rails.root.join('db/structure.sql')

  # Schema search path
  config.search_path = 'public'

  # Feature toggles
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true
  config.include_materialized_views = true
  config.include_sequences = true
  config.include_custom_types = true
  config.include_domains = true

  # Schema versioning (stores schema history in database, similar to Rails' ar_internal_metadata)
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails schema dump/load tasks
  # When true, db:schema:dump and db:schema:load will use BetterStructureSql automatically
  config.replace_default_dump = true
  config.replace_default_load = true
end
