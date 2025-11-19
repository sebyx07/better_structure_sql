BetterStructureSql.configure do |config|
  # Output file path (default: "db/structure.sql")
  # config.output_path = "db/structure.sql"

  # Search path for schema (default: '"$user", public')
  # config.search_path = '"$user", public'

  # Replace Rails' default db:schema:dump task (default: false)
  # Set to true to automatically use BetterStructureSql for all schema dumps
  # config.replace_default_dump = false

  # Include PostgreSQL extensions (default: true)
  # config.include_extensions = true

  # Include functions (default: false, Phase 3 feature)
  # config.include_functions = false

  # Include triggers (default: false, Phase 3 feature)
  # config.include_triggers = false

  # Include views (default: false, Phase 3 feature)
  # config.include_views = false

  # Enable schema version storage (default: false, Phase 2 feature)
  # config.enable_schema_versions = false

  # Number of schema versions to keep (default: 10, 0 = unlimited)
  # config.schema_versions_limit = 10

  # Indentation size for SQL formatting (default: 2)
  # config.indent_size = 2

  # Add spacing between sections (default: true)
  # config.add_section_spacing = true

  # Sort tables alphabetically (default: true)
  # config.sort_tables = true
end
