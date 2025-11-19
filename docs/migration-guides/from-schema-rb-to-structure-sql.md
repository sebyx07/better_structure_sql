# Migrating from schema.rb to structure.sql

This guide walks you through migrating your Rails application from Ruby schema format (`schema.rb`) to SQL schema format (`structure.sql`) using BetterStructureSql.

## Why Migrate?

**schema.rb limitations:**
- Cannot represent PostgreSQL-specific features (extensions, custom types, functions, triggers, views)
- Limited to Active Record's abstraction layer
- Missing advanced features like partial indexes, expression indexes, check constraints
- Cannot capture custom SQL features

**structure.sql advantages:**
- Full PostgreSQL feature support (extensions, types, functions, triggers, views)
- Preserves all database features exactly as created
- Better for PostgreSQL-heavy applications
- More accurate database restoration
- Works with native PostgreSQL features

**BetterStructureSql benefits:**
- Cleaner than pg_dump (no version comments, no cluster metadata)
- Deterministic output (consistent formatting, sorted objects)
- No pg_dump binary dependency
- Version tracking and comparison capabilities

## Migration Steps

### 1. Install BetterStructureSql

Add to your `Gemfile`:

```ruby
gem 'better_structure_sql'
```

Run:

```bash
bundle install
rails generate better_structure_sql:install
rails db:migrate
```

### 2. Configure for SQL Format

Edit `config/application.rb`:

```ruby
module YourApp
  class Application < Rails::Application
    # ... other config ...

    # Change from :ruby to :sql
    config.active_record.schema_format = :sql
  end
end
```

Or set via environment variable for flexibility:

```ruby
config.active_record.schema_format = ENV.fetch('SCHEMA_FORMAT', 'sql').to_sym
```

### 3. Update Initializer (Optional)

Edit `config/initializers/better_structure_sql.rb` to respect the schema format:

```ruby
BetterStructureSql.configure do |config|
  # Dynamic output path based on schema format
  schema_file = Rails.application.config.active_record.schema_format == :ruby ? 'db/schema.rb' : 'db/structure.sql'
  config.output_path = Rails.root.join(schema_file)

  # Enable all PostgreSQL features
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true

  # Enable schema versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails dump/load
  config.replace_default_dump = true
  config.replace_default_load = true
end
```

### 4. Store Your Last schema.rb Version (Optional)

Before switching formats, you can store your current Ruby schema as a version for historical reference:

```bash
# Make sure schema.rb is up to date
rails db:schema:dump

# Store the Ruby schema version
rails db:schema:store
```

This creates a snapshot in the database that you can reference later.

### 5. Generate structure.sql

```bash
# Generate the new structure.sql
rails db:schema:dump
```

This creates `db/structure.sql` using BetterStructureSql's clean format.

### 6. Store structure.sql Version

```bash
# Store the SQL schema version
rails db:schema:store
```

### 7. Update .gitignore (Optional)

If you no longer need schema.rb, add it to `.gitignore`:

```
# Ignore old schema.rb (now using structure.sql)
/db/schema.rb
```

Or keep both if you want flexibility:

```
# Keep both formats in git
!/db/schema.rb
!/db/structure.sql
```

### 8. Verify the Migration

Test that schema loading works:

```bash
# Drop and recreate database (WARNING: destroys data)
rails db:drop db:create

# Load schema from structure.sql
rails db:schema:load

# Run migrations to ensure up-to-date
rails db:migrate

# Verify everything works
rails db:test:prepare
bundle exec rspec  # or your test suite
```

### 9. Update CI/CD

Update your CI pipeline to use structure.sql:

```yaml
# Example GitHub Actions
- name: Setup Database
  run: |
    cp config/database.yml.ci config/database.yml
    rails db:create
    rails db:schema:load  # Uses structure.sql now

# Example CircleCI
- run:
    name: Setup Database
    command: |
      bundle exec rails db:create
      bundle exec rails db:schema:load
```

### 10. Update Team Documentation

Inform your team:

1. New schema format (structure.sql instead of schema.rb)
2. New workflow for schema changes
3. How to store schema versions

## Switching Between Formats

You can easily switch between formats using the environment variable:

```bash
# Dump as Ruby format
SCHEMA_FORMAT=ruby rails db:schema:dump

# Dump as SQL format
SCHEMA_FORMAT=sql rails db:schema:dump

# Store either format
SCHEMA_FORMAT=ruby rails db:schema:store
SCHEMA_FORMAT=sql rails db:schema:store
```

## Comparing Formats

You can store both formats as versions and compare them:

```bash
# Dump and store Ruby version
SCHEMA_FORMAT=ruby rails db:schema:dump
SCHEMA_FORMAT=ruby rails db:schema:store

# Dump and store SQL version
SCHEMA_FORMAT=sql rails db:schema:dump
SCHEMA_FORMAT=sql rails db:schema:store

# View all versions in web UI
# Navigate to /better_structure_sql/schema_versions
```

The web UI shows:
- Format type (SQL vs Ruby) with color-coded badges
- File size comparison
- Side-by-side viewing
- Download capability for both formats

## Rollback Plan

If you need to rollback to schema.rb:

1. Change `config/application.rb`:
   ```ruby
   config.active_record.schema_format = :ruby
   ```

2. Generate schema.rb:
   ```bash
   rails db:schema:dump
   ```

3. Update .gitignore if needed

4. Commit the change:
   ```bash
   git add config/application.rb db/schema.rb
   git commit -m "Rollback to schema.rb format"
   ```

## Best Practices

1. **Store versions before major changes** - Run `rails db:schema:store` before big migrations
2. **Review structure.sql diffs** - Check git diffs to understand schema changes
3. **Use version limit** - Keep `schema_versions_limit` reasonable (10-20) to avoid bloat
4. **Test schema:load** - Regularly verify `rails db:schema:load` works correctly
5. **Document PostgreSQL features** - Add comments explaining custom functions, triggers, etc.

## Troubleshooting

### schema:load fails with "relation already exists"

**Cause**: Database not fully dropped before loading

**Solution**:
```bash
rails db:drop db:create db:schema:load
```

### Missing PostgreSQL features in structure.sql

**Cause**: Features not enabled in configuration

**Solution**: Edit `config/initializers/better_structure_sql.rb`:
```ruby
config.include_extensions = true
config.include_functions = true
config.include_triggers = true
config.include_views = true
```

### Cannot store schema version

**Cause**: Migration not run or table doesn't exist

**Solution**:
```bash
rails generate better_structure_sql:install
rails db:migrate
```

### Huge structure.sql file (>10MB)

**Cause**: Large database with many objects

**Solution**: This is normal for large databases. BetterStructureSql efficiently handles large files with streaming and memory protection.

## Additional Resources

- [BetterStructureSql README](../../README.md)
- [Configuration Guide](../configuration.md)
- [Schema Versioning Guide](../features/schema-versioning.md)
- [PostgreSQL Features Support](../postgresql-features.md)
