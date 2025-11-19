# Configuration

BetterStructureSql is configured via `config/initializers/better_structure_sql.rb`.

## Complete Configuration Example

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # ========================================
  # Core Settings
  # ========================================

  # Replace Rails' default rake db:schema:dump task (opt-in)
  # Default: false
  # When false, use explicit task: rails db:schema:dump_better
  config.replace_default_dump = false

  # Output file path (relative to Rails.root)
  # Default: 'db/structure.sql'
  config.output_path = 'db/structure.sql'

  # Schema search path
  # Default: '"$user", public'
  config.search_path = '"$user", public'

  # ========================================
  # Schema Components
  # ========================================

  # Include PostgreSQL extensions (e.g., pgcrypto, uuid-ossp)
  # Default: true
  config.include_extensions = true

  # Include database functions
  # Default: true
  config.include_functions = true

  # Include triggers
  # Default: true
  config.include_triggers = true

  # Include views (regular and materialized)
  # Default: true
  config.include_views = true

  # Include sequences (auto-generated sequences are always included)
  # Default: true
  config.include_sequences = true

  # Include custom types and enums
  # Default: true
  config.include_custom_types = true

  # ========================================
  # Schema Versioning (Optional)
  # ========================================

  # Enable schema version storage
  # Default: false
  config.enable_schema_versions = true

  # Number of schema versions to keep (0 = unlimited)
  # Default: 10
  config.schema_versions_limit = 10

  # Table name for schema versions
  # Default: 'better_structure_sql_schema_versions'
  config.schema_versions_table = 'better_structure_sql_schema_versions'

  # ========================================
  # Formatting
  # ========================================

  # Number of spaces for indentation
  # Default: 2
  config.indent_size = 2

  # Add blank lines between major sections
  # Default: true
  config.add_section_spacing = true

  # Sort tables alphabetically
  # Default: true
  config.sort_tables = true

  # Sort indexes alphabetically within each table
  # Default: true
  config.sort_indexes = true
end
```

## Configuration Options Reference

### Core Settings

#### `replace_default_dump`
**Type**: Boolean
**Default**: `false`

When `true`, replaces Rails' `rake db:schema:dump` task with BetterStructureSql.

```ruby
config.replace_default_dump = true
# Now `rails db:schema:dump` uses BetterStructureSql
```

#### `output_path`
**Type**: String
**Default**: `'db/structure.sql'`

Path where the structure file will be written (relative to `Rails.root`).

```ruby
config.output_path = 'db/better_structure.sql'
```

#### `search_path`
**Type**: String
**Default**: `'"$user", public'`

PostgreSQL search path to set in the generated structure file.

```ruby
config.search_path = 'public, shared'
```

### Schema Components

Control which database objects are included in the dump.

#### `include_extensions`
**Type**: Boolean
**Default**: `true`

Include PostgreSQL extensions (e.g., `pgcrypto`, `uuid-ossp`, `hstore`).

```ruby
config.include_extensions = true
# Output: CREATE EXTENSION IF NOT EXISTS pgcrypto;
```

#### `include_functions`
**Type**: Boolean
**Default**: `true`

Include database functions.

```ruby
config.include_functions = true
```

#### `include_triggers`
**Type**: Boolean
**Default**: `true`

Include triggers.

```ruby
config.include_triggers = true
```

#### `include_views`
**Type**: Boolean
**Default**: `true`

Include both regular and materialized views.

```ruby
config.include_views = true
```

#### `include_sequences`
**Type**: Boolean
**Default**: `true`

Include standalone sequences (sequences created by serial columns are always included).

```ruby
config.include_sequences = true
```

#### `include_custom_types`
**Type**: Boolean
**Default**: `true`

Include custom types and enums.

```ruby
config.include_custom_types = true
```

### Schema Versioning

#### `enable_schema_versions`
**Type**: Boolean
**Default**: `false`

Enable schema version storage in the database.

```ruby
config.enable_schema_versions = true
```

When enabled:
- Each `db:schema:dump_better` or `db:schema:store` creates a version record
- Versions include PostgreSQL version, type (SQL/Ruby), timestamp
- Old versions are automatically cleaned up based on `schema_versions_limit`

#### `schema_versions_limit`
**Type**: Integer
**Default**: `10`

Number of schema versions to retain. Set to `0` for unlimited.

```ruby
config.schema_versions_limit = 20  # Keep last 20 versions
config.schema_versions_limit = 0   # Keep all versions
```

#### `schema_versions_table`
**Type**: String
**Default**: `'better_structure_sql_schema_versions'`

Table name for storing schema versions.

```ruby
config.schema_versions_table = 'schema_versions'
```

### Formatting

#### `indent_size`
**Type**: Integer
**Default**: `2`

Number of spaces for indentation.

```ruby
config.indent_size = 4
```

#### `add_section_spacing`
**Type**: Boolean
**Default**: `true`

Add blank lines between sections (extensions, tables, views, etc.).

```ruby
config.add_section_spacing = false  # More compact output
```

#### `sort_tables`
**Type**: Boolean
**Default**: `true`

Sort tables alphabetically in the output.

```ruby
config.sort_tables = true
```

#### `sort_indexes`
**Type**: Boolean
**Default**: `true`

Sort indexes alphabetically within each table.

```ruby
config.sort_indexes = true
```

## Common Configuration Scenarios

### Minimal Configuration

Clean schema dumps without extra features:

```ruby
BetterStructureSql.configure do |config|
  config.replace_default_dump = true
  config.enable_schema_versions = false
end
```

### Development Team Configuration

Store versions for easy sharing:

```ruby
BetterStructureSql.configure do |config|
  config.replace_default_dump = true
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```

### CI/CD Configuration

Fast dumps with minimal features:

```ruby
BetterStructureSql.configure do |config|
  config.replace_default_dump = true
  config.enable_schema_versions = false
  config.include_functions = false
  config.include_triggers = false
  config.include_views = false
end
```

### Schema-Only Configuration

Only tables and indexes:

```ruby
BetterStructureSql.configure do |config|
  config.include_extensions = false
  config.include_functions = false
  config.include_triggers = false
  config.include_views = false
  config.include_sequences = false
  config.include_custom_types = false
end
```

## Environment-Specific Configuration

You can configure per environment:

```ruby
BetterStructureSql.configure do |config|
  config.replace_default_dump = true

  if Rails.env.production?
    config.enable_schema_versions = true
    config.schema_versions_limit = 50
  elsif Rails.env.development?
    config.enable_schema_versions = true
    config.schema_versions_limit = 5
  else
    config.enable_schema_versions = false
  end
end
```

## Next Steps

- [Usage Guide](usage.md)
- [Schema Versions](schema_versions.md)
