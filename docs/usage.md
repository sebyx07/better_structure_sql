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

### Manually Adding Schema Versions in Production

If you have an existing `schema.rb` or `structure.sql` in production but no stored schema versions, you can manually add them to the database.

#### Scenario: Production Database Without Version History

You have:
- Production database running with current schema
- No stored schema versions (table exists but empty)
- Want to capture current schema as baseline

#### Solution 1: Store Current Production Schema

From production environment:

```bash
# Generate and store current schema in one step
RAILS_ENV=production rails db:schema:dump_better
RAILS_ENV=production rails db:schema:store
```

Or programmatically in Rails console:

```ruby
# Production Rails console
BetterStructureSql::Dumper.dump(output_path: 'db/structure.sql')
BetterStructureSql::SchemaVersions.store_current
```

#### Solution 2: Import Existing Schema File

If you have an existing `schema.rb` or `structure.sql` that matches production:

```ruby
# Production Rails console
content = File.read(Rails.root.join('db', 'structure.sql'))
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)
```

For `schema.rb`:

```ruby
# Production Rails console
content = File.read(Rails.root.join('db', 'schema.rb'))
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'rb',
  pg_version: db_version
)
```

#### Solution 3: Copy from Development to Production

If development has schema versions but production doesn't:

```ruby
# Development: Export latest version
dev_version = BetterStructureSql::SchemaVersions.latest
File.write('tmp/schema_export.sql', dev_version.content)
```

```bash
# Copy to production server
scp tmp/schema_export.sql production-server:/tmp/
```

```ruby
# Production Rails console
content = File.read('/tmp/schema_export.sql')
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)
```

#### Solution 4: Backfill Historical Versions from Git

If you have historical schema files in git:

```bash
# Extract schema from specific git commits
git show main~10:db/structure.sql > /tmp/schema_v1.sql
git show main~5:db/structure.sql > /tmp/schema_v2.sql
git show main:db/structure.sql > /tmp/schema_v3.sql
```

```ruby
# Production Rails console
db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')

# Store historical versions (oldest first)
['/tmp/schema_v1.sql', '/tmp/schema_v2.sql', '/tmp/schema_v3.sql'].each do |file|
  content = File.read(file)
  BetterStructureSql::SchemaVersions.store(
    content: content,
    format_type: 'sql',
    pg_version: db_version
  )
  sleep 1  # Ensure different timestamps
end
```

#### Solution 5: Multi-File Schema Import

For multi-file schema output stored in git:

```bash
# Extract multi-file schema directory from git commit
git archive --format=tar main:db/schema | tar -x -C /tmp/schema_export
```

```ruby
# Production Rails console
require 'zip'

db_version = ActiveRecord::Base.connection.select_value('SHOW server_version')
schema_dir = '/tmp/schema_export'

# Create ZIP from directory
zip_buffer = BetterStructureSql::ZipGenerator.create_from_directory(schema_dir)

BetterStructureSql::SchemaVersions.store(
  zip_archive: zip_buffer.string,
  output_mode: 'multi_file',
  pg_version: db_version
)
```

#### Verification

After adding versions, verify they were stored correctly:

```ruby
# Check count
BetterStructureSql::SchemaVersions.count
# => 3

# List versions
BetterStructureSql::SchemaVersions.all_versions.each do |v|
  puts "ID: #{v.id}, Created: #{v.created_at}, Size: #{v.formatted_size}"
end

# Verify latest version content
latest = BetterStructureSql::SchemaVersions.latest
puts latest.content.lines.first(10)
```

#### Common Issues

**Issue**: "Table doesn't exist error"
```bash
# Solution: Run migration to create table
RAILS_ENV=production rails db:migrate
```

**Issue**: "Permission denied when reading file"
```bash
# Solution: Ensure Rails process has read access
chmod 644 db/structure.sql
```

**Issue**: "Database version mismatch"
```ruby
# Solution: Get correct database version
db_version = case ActiveRecord::Base.connection.adapter_name
when 'PostgreSQL'
  ActiveRecord::Base.connection.select_value('SHOW server_version')
when 'Mysql2'
  ActiveRecord::Base.connection.select_value('SELECT VERSION()')
when 'SQLite'
  ActiveRecord::Base.connection.select_value('SELECT sqlite_version()')
end

# Use correct version when storing
BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'sql',
  pg_version: db_version
)
```

#### Automated Production Baseline Script

Create a one-time setup script:

```ruby
# lib/tasks/schema_baseline.rake
namespace :db do
  namespace :schema do
    desc 'Create baseline schema version from current database'
    task baseline: :environment do
      puts "Creating baseline schema version..."

      # Dump current schema
      BetterStructureSql::Dumper.dump(output_path: 'db/structure.sql')

      # Store as version
      BetterStructureSql::SchemaVersions.store_current

      latest = BetterStructureSql::SchemaVersions.latest
      puts "✓ Baseline created: ID #{latest.id}, Size #{latest.formatted_size}"
      puts "Total versions: #{BetterStructureSql::SchemaVersions.count}"
    end
  end
end
```

Usage:
```bash
RAILS_ENV=production rails db:schema:baseline
```

## Next Steps

- [Schema Versions](schema_versions.md)
- [Configuration](configuration.md)
