# Installation

## Basic Installation

Add BetterStructureSql to your Rails application's Gemfile:

```ruby
# Gemfile
gem 'better_structure_sql'

# Database adapter (choose one based on your database)
gem 'pg'       # For PostgreSQL (primary support)
gem 'mysql2'   # For MySQL 8.0+ (experimental)
gem 'sqlite3'  # For SQLite 3.35+ (experimental)
```

**Note**: The gem currently requires the `pg` gem as a dependency. Multi-database adapters (MySQL, SQLite) are implemented but require manual gem installation.

Install the gem:

```bash
bundle install
```

## Setup

Run the installation generator to create configuration and migration files:

```bash
rails generate better_structure_sql:install
```

This creates:
- `config/initializers/better_structure_sql.rb` - Configuration file
- Migration for `better_structure_sql_schema_versions` table (if schema versions enabled)

## Minimal Setup (No Schema Versions)

If you only want clean `structure.sql` generation without version storage:

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.replace_default_dump = true
  config.enable_schema_versions = false
end
```

Then run:

```bash
rails db:schema:dump_better
```

## Full Setup (With Schema Versions)

For complete functionality including schema version storage:

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Replace Rails default
  config.replace_default_dump = true

  # Enable schema versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10  # Keep last 10 versions
end
```

Run the installation task to create the schema versions table:

```bash
rails generate better_structure_sql:install
rails db:migrate
```

## Replace Default `rake db:schema:dump`

To make BetterStructureSql the default for `rake db:schema:dump`:

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.replace_default_dump = true
end
```

Now when you run:

```bash
rails db:schema:dump
```

It will use BetterStructureSql instead of pg_dump.

## Manual Usage

If you prefer explicit control, leave `replace_default_dump = false` and use:

```bash
rails db:schema:dump_better
```

## Verify Installation

After installation, generate a schema dump:

```bash
rails db:schema:dump_better
```

Check `db/structure.sql` - it should be clean without database-specific dump tool noise!

## Database Configuration

BetterStructureSql **auto-detects** your database adapter from ActiveRecord. Ensure your `config/database.yml` is configured correctly:

### PostgreSQL (Primary Support)

```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: your_app_development
  pool: 5
  host: localhost
```

### MySQL (Experimental)

```yaml
development:
  adapter: mysql2
  encoding: utf8mb4
  collation: utf8mb4_unicode_ci
  database: your_app_development
  pool: 5
  host: localhost
```

### SQLite (Experimental)

```yaml
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
```

## Requirements

- **Rails**: 7.0 or higher
- **Ruby**: 2.7 or higher
- **Database**:
  - PostgreSQL 12+ (production-ready)
  - MySQL 8.0+ (experimental)
  - SQLite 3.35+ (experimental)
- **Gems**: `rubyzip >= 2.0.0` (for multi-file ZIP support)

## Troubleshooting

### "Table doesn't exist" Error

If schema versions are enabled, make sure you ran migrations:

```bash
rails db:migrate
```

### Schema Not Generating

Check that you have:
1. A valid database connection
2. Migrations run (`rails db:migrate`)
3. Tables in your database

### Permission Issues

Ensure your database user has permissions to query metadata tables:

**PostgreSQL**:
- `information_schema` tables
- `pg_catalog` tables (for extensions, functions, triggers)
- Your application schemas

**MySQL**:
- `information_schema` tables
- `mysql.proc` table (for stored procedures)
- `SHOW` privileges

**SQLite**:
- Read access to `sqlite_master` table
- PRAGMA query permissions

## Next Steps

- [Configuration Options](configuration.md)
- [Usage Guide](usage.md)
- [Schema Versions](schema_versions.md)
