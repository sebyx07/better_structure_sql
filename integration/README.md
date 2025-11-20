# BetterStructureSql Integration App (PostgreSQL)

This is a comprehensive integration/testing app for BetterStructureSql that demonstrates all PostgreSQL features and provides a real-world example of multi-file schema output.

## Purpose

1. **Feature Demonstration**: Shows off all PostgreSQL capabilities supported by BetterStructureSql
2. **Testing Environment**: Used for integration testing and CI/CD validation
3. **Real-World Example**: Generates actual multi-file schema output as a reference
4. **Development Playground**: Try out new features and configuration options

## What's Included

### Database Features Demonstrated

This app includes examples of:

- ✅ **PostgreSQL Extensions**: `pgcrypto`, `uuid-ossp`, `pg_trgm`
- ✅ **Custom Types**: ENUM types for status fields
- ✅ **Functions**: PL/pgSQL functions for business logic
- ✅ **Triggers**: BEFORE/AFTER triggers with function calls
- ✅ **Sequences**: Custom sequences for ID generation
- ✅ **Views**: Regular SQL views for denormalized queries
- ✅ **Materialized Views**: Cached aggregated data
- ✅ **Foreign Keys**: All constraint actions (CASCADE, RESTRICT, SET NULL)
- ✅ **Indexes**: btree, gin, gist, partial indexes, expression indexes
- ✅ **Domains**: Custom constrained types
- ✅ **Check Constraints**: Table-level validation
- ✅ **Array Types**: PostgreSQL array columns
- ✅ **JSONB**: JSON data with indexing

### Migration Count

**11 migrations** implementing a feature-rich e-commerce-style schema.

### Generated Schema Output

When running `rails db:schema:dump_better`, this app generates:

```
db/schema/
├── _header.sql              # 95 bytes - SET statements
├── _manifest.json           # 763 bytes - Metadata
├── 01_extensions/
│   └── 000001.sql          # 3 lines - PostgreSQL extensions
├── 02_types/
│   └── 000001.sql          # 13 lines - ENUM types
├── 03_functions/
│   └── 000001.sql          # 332 lines - PL/pgSQL functions
├── 04_sequences/
│   └── 000001.sql          # 289 lines - Sequence definitions
├── 05_tables/
│   ├── 000001.sql          # 500 lines - Main tables (part 1)
│   └── 000002.sql          # 479 lines - Main tables (part 2)
├── 06_indexes/
│   └── 000001.sql          # 397 lines - All indexes
├── 07_foreign_keys/
│   └── 000001.sql          # 67 lines - Foreign key constraints
├── 08_views/
│   └── 000001.sql          # 217 lines - Views and materialized views
├── 09_triggers/
│   └── 000001.sql          # 35 lines - Trigger definitions
└── 10_migrations/
    └── 000001.sql          # 13 lines - Schema migrations INSERT
```

**Total**: 11 files, 2,345 lines of clean SQL across 10 directories

## Quick Start

### Using Docker (Recommended)

```bash
# From project root
docker compose up

# Access the app at http://localhost:3000
```

### Local Development

1. **Setup Database**:
   ```bash
   # Ensure PostgreSQL 12+ is running locally
   createdb integration_development
   ```

2. **Install Dependencies**:
   ```bash
   cd integration
   bundle install
   ```

3. **Run Migrations**:
   ```bash
   bundle exec rails db:migrate
   ```

4. **Generate Schema**:
   ```bash
   bundle exec rails db:schema:dump_better
   ```

5. **View Output**:
   ```bash
   ls -R db/schema/
   cat db/schema/_manifest.json
   ```

## Configuration

See `config/initializers/better_structure_sql.rb` for the configuration used in this app:

```ruby
BetterStructureSql.configure do |config|
  # Multi-file output mode
  config.output_path = 'db/schema'

  # Chunking settings
  config.max_lines_per_file = 500
  config.overflow_threshold = 1.1
  config.generate_manifest = true

  # Enable all PostgreSQL features
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true
  config.include_materialized_views = true
  config.include_domains = true
  config.include_sequences = true
  config.include_custom_types = true

  # Schema versioning enabled
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Replace default Rails tasks
  config.replace_default_dump = true
  config.replace_default_load = true
end
```

## Web UI

The integration app mounts the BetterStructureSql web UI at `/schema_versions`:

```bash
# Start the server
bundle exec rails server

# Visit http://localhost:3000/schema_versions
```

Features:
- Browse all stored schema versions
- View formatted SQL with syntax highlighting
- Download individual versions
- Download ZIP archives of multi-file schemas
- View manifest metadata

## Testing

### Run Test Suite

```bash
bundle exec rspec
```

### Manual Testing Workflow

1. **Modify Schema**: Add a new migration
2. **Run Migration**: `rails db:migrate`
3. **Generate Schema**: `rails db:schema:dump_better`
4. **Store Version**: `rails db:schema:store`
5. **List Versions**: `rails db:schema:versions`
6. **View Web UI**: Visit `/schema_versions`

### Test Schema Loading

```bash
# Drop and recreate database
bundle exec rails db:drop db:create

# Load from multi-file schema
bundle exec rails db:schema:load_better

# Verify
bundle exec rails db:schema:dump_better
diff -r db/schema db/schema_backup  # Should be identical
```

## Example Queries

### Check Generated Schema

```bash
# View extensions
cat db/schema/01_extensions/000001.sql

# View custom types
cat db/schema/02_types/000001.sql

# View functions
cat db/schema/03_functions/000001.sql

# View first table file
cat db/schema/05_tables/000001.sql | head -50

# View manifest
cat db/schema/_manifest.json | jq
```

### Database Inspection

```sql
-- Connect to database
psql integration_development

-- List extensions
\dx

-- List custom types
\dT+

-- List functions
\df

-- List triggers
SELECT tgname FROM pg_trigger WHERE tgisinternal = false;

-- List views
\dv

-- List materialized views
\dm
```

## Troubleshooting

### Schema Not Generating

1. Check database connection in `config/database.yml`
2. Ensure migrations have run: `rails db:migrate:status`
3. Check logs in `log/development.log`

### Permission Errors

Ensure your PostgreSQL user has permissions:
```sql
GRANT SELECT ON information_schema.tables TO your_user;
GRANT SELECT ON pg_catalog.pg_class TO your_user;
```

### Multi-File Output Not Working

1. Verify `config.output_path` is a directory (e.g., `'db/schema'`)
2. Check that directory is writable
3. Ensure `config.generate_manifest = true`

## Development

### Adding New Features

1. Create a new migration demonstrating the feature
2. Run migration and generate schema
3. Verify output in `db/schema/`
4. Commit both migration and generated schema

### Resetting Database

```bash
# Complete reset
bundle exec rails db:drop db:create db:migrate db:schema:dump_better

# Just regenerate schema
rm -rf db/schema/
bundle exec rails db:schema:dump_better
```

## CI/CD

This integration app is used in GitHub Actions CI:

```yaml
# .github/workflows/ci.yml
- name: Run Integration Tests
  run: |
    cd integration
    bundle exec rails db:create db:migrate
    bundle exec rails db:schema:dump_better
    bundle exec rails db:schema:load_better
    bundle exec rspec
```

## File Structure

```
integration/
├── app/                     # Rails app (controllers, models, views)
├── config/
│   ├── database.yml         # PostgreSQL configuration
│   └── initializers/
│       └── better_structure_sql.rb  # Gem configuration
├── db/
│   ├── migrate/            # 11 migrations
│   └── schema/             # Generated multi-file schema
├── Gemfile                  # Dependencies including better_structure_sql
└── README.md               # This file
```

## Learn More

- [Main README](../README.md)
- [Configuration Guide](../docs/configuration.md)
- [Multi-File Schema Documentation](../docs/features/multi-file-schema-output/README.md)
- [Schema Versioning Guide](../docs/schema_versions.md)

## License

Part of the BetterStructureSql project. See [LICENSE](../LICENSE).
