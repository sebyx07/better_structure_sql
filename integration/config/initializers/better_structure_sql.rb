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

  # Schema versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails schema dump and load
  config.replace_default_dump = true
  config.replace_default_load = true
end
