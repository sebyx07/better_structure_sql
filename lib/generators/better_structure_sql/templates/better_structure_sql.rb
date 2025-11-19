# frozen_string_literal: true

BetterStructureSql.configure do |config|
  # Output path for structure dump
  # Single file: 'db/structure.sql'
  # Multi-file: 'db/schema' (directory) - RECOMMENDED for large projects
  #   Benefits: better git diffs, easier navigation, AI-friendly organization
  # NOTE: BetterStructureSql only supports SQL format dumps (structure.sql).
  #       Using 'db/schema.rb' will skip replacement of dump/load tasks (can still store versions).
  config.output_path = Rails.root.join('db/structure.sql')

  # Schema search path (PostgreSQL only)
  config.search_path = 'public'

  # Feature toggles - what to include in dumps
  # Features auto-skip if not supported by your database
  config.include_extensions = true          # PostgreSQL only
  config.include_custom_types = true        # PostgreSQL (ENUM, composite), MySQL (ENUM/SET)
  config.include_domains = true             # PostgreSQL only
  config.include_sequences = true           # PostgreSQL only
  config.include_functions = true           # PostgreSQL, MySQL (stored procedures)
  config.include_triggers = true            # All databases
  config.include_views = true               # All databases
  config.include_materialized_views = true  # PostgreSQL only

  # Output formatting
  config.add_section_spacing = true # Add blank lines between sections
  config.sort_tables = false        # Sort tables alphabetically (or use dependency order)

  # Multi-file output settings (only used when output_path is a directory)
  config.max_lines_per_file = 500 # Target lines per file (soft limit)
  config.overflow_threshold = 1.1       # Allow files to be up to 10% larger to avoid tiny files
  config.generate_manifest = true       # Generate _manifest.json with statistics

  # Schema versioning (stores schema history in database for rollback/comparison)
  config.enable_schema_versions = true  # Store versions in database
  config.schema_versions_limit = 10     # Keep last 10 versions (0 = unlimited)

  # Replace default Rails schema dump/load tasks
  # When true, db:schema:dump and db:schema:load will use BetterStructureSql automatically
  # This also automatically sets config.active_record.schema_format = :sql
  # NOTE: Only works with SQL format. Silently ignored if output_path ends with '.rb'
  config.replace_default_dump = true
  config.replace_default_load = true
end
