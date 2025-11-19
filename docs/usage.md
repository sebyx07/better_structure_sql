# Usage

## Rake Tasks

### `db:schema:dump_better`

Generate clean structure.sql using BetterStructureSql.

```bash
rails db:schema:dump_better
```

Output: `db/structure.sql`

### `db:schema:dump` (Replacement)

When `replace_default_dump = true`, this task uses BetterStructureSql instead of pg_dump.

```bash
rails db:schema:dump
```

### `db:schema:store`

Store current schema version in database (requires `enable_schema_versions = true`).

```bash
rails db:schema:store
```

Creates version record with:
- PostgreSQL version
- Schema content (SQL or Ruby)
- Format type
- Timestamp

### `db:schema:versions`

List all stored schema versions.

```bash
rails db:schema:versions
```

Output:
```
Schema Versions (10 total):
  #1 - 2024-01-15 10:30:45 UTC - PostgreSQL 14.5 (sql)
  #2 - 2024-01-16 14:22:10 UTC - PostgreSQL 14.5 (sql)
  #3 - 2024-01-17 09:15:33 UTC - PostgreSQL 14.5 (sql)
```

### `db:schema:cleanup`

Manually trigger schema version cleanup (respects `schema_versions_limit`).

```bash
rails db:schema:cleanup
```

## Workflow Examples

### Basic Workflow

```bash
# Make schema changes
rails generate migration AddEmailToUsers email:string
rails db:migrate

# Generate clean structure.sql
rails db:schema:dump_better

# Commit to git
git add db/structure.sql
git commit -m "Add email to users"
```

### With Schema Versioning

```bash
# After migration
rails db:migrate

# Dump and store version
rails db:schema:dump_better
rails db:schema:store

# Or combine
rails db:migrate && rails db:schema:dump_better && rails db:schema:store
```

### Automated Storage After Migration

Add to `db/migrate/` or Rake task:

```ruby
# lib/tasks/db.rake
namespace :db do
  namespace :migrate do
    task :with_schema_store do
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:schema:dump_better'].invoke
      Rake::Task['db:schema:store'].invoke if BetterStructureSql.config.enable_schema_versions
    end
  end
end
```

Usage:
```bash
rails db:migrate:with_schema_store
```

### CI/CD Integration

```yaml
# .github/workflows/ci.yml
- name: Setup database
  run: |
    rails db:create
    rails db:schema:load
    rails db:migrate

- name: Generate schema
  run: rails db:schema:dump_better

- name: Check for schema changes
  run: |
    git diff --exit-code db/structure.sql || \
    (echo "Schema changes detected!" && exit 1)
```

## Programmatic Usage

### Generate Schema from Ruby

```ruby
require 'better_structure_sql'

# Generate structure.sql
BetterStructureSql::Dumper.dump

# Custom output path
BetterStructureSql::Dumper.dump(output_path: 'tmp/schema.sql')

# Return as string
schema_sql = BetterStructureSql::Dumper.dump_to_string
```

### Store Schema Version

```ruby
# Store current schema
BetterStructureSql::SchemaVersions.store_current

# Store custom content
BetterStructureSql::SchemaVersions.store(
  content: custom_sql,
  format_type: 'sql',
  pg_version: '14.5'
)
```

### Query Schema Versions

```ruby
# Get latest version
latest = BetterStructureSql::SchemaVersions.latest
puts latest.content
puts latest.pg_version
puts latest.created_at

# Get all versions
versions = BetterStructureSql::SchemaVersions.all_versions

# Get specific version
version = BetterStructureSql::SchemaVersions.find_by_id(5)
```

## Integration Patterns

### Git Hooks

Pre-commit hook to ensure schema is up to date:

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check if migrations changed
if git diff --cached --name-only | grep -q "db/migrate"; then
  echo "Migrations changed, checking schema..."

  rails db:schema:dump_better

  if git diff --name-only | grep -q "db/structure.sql"; then
    echo "ERROR: Schema out of date. Run: rails db:schema:dump_better"
    exit 1
  fi
fi
```

### Database Seeding

```ruby
# db/seeds.rb

# Load structure
system('rails db:schema:load')

# Store initial version
BetterStructureSql::SchemaVersions.store_current if BetterStructureSql.config.enable_schema_versions

# Create seed data
User.create!(email: 'admin@example.com')
```

### Testing

```ruby
# spec/rails_helper.rb

RSpec.configure do |config|
  config.before(:suite) do
    # Ensure schema is current
    system('rails db:schema:load RAILS_ENV=test')

    # Store test schema version
    BetterStructureSql::SchemaVersions.store_current if BetterStructureSql.config.enable_schema_versions
  end
end
```

## Common Tasks

### Compare Schema Versions

```ruby
v1 = BetterStructureSql::SchemaVersions.find(1)
v2 = BetterStructureSql::SchemaVersions.find(2)

# Write to temp files for diff
File.write('/tmp/v1.sql', v1.content)
File.write('/tmp/v2.sql', v2.content)

system('diff /tmp/v1.sql /tmp/v2.sql')
```

### Export Schema Version

```ruby
version = BetterStructureSql::SchemaVersions.latest

File.write("schema_#{version.id}.sql", version.content)
```

### Restore from Version

```ruby
version = BetterStructureSql::SchemaVersions.find(5)

File.write('db/structure.sql', version.content)
system('rails db:schema:load')
```

## Performance

Large databases (1000+ tables):

```ruby
# Use specific schemas only
BetterStructureSql.configure do |config|
  config.search_path = 'public'  # Skip other schemas
end

# Disable unused features
BetterStructureSql.configure do |config|
  config.include_functions = false
  config.include_triggers = false
  config.include_views = false
end
```

Typical performance:
- 50 tables: ~1-2 seconds
- 200 tables: ~3-5 seconds
- 500 tables: ~8-12 seconds

## Troubleshooting

### Schema Not Updating

```bash
# Clear cached schema
rm db/structure.sql

# Regenerate
rails db:schema:dump_better
```

### Version Storage Failing

```bash
# Ensure table exists
rails db:migrate

# Check configuration
rails runner "puts BetterStructureSql.config.enable_schema_versions"
```

### Permission Errors

Grant necessary permissions:

```sql
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO your_user;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO your_user;
```

## Next Steps

- [Schema Versions](schema_versions.md)
- [Configuration](configuration.md)
