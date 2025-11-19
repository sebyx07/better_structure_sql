# BetterStructureSql 🚀

Clean, maintainable PostgreSQL schema dumps for Rails without pg_dump noise.

## Why BetterStructureSql? 🤔

Rails' `pg_dump` creates noisy `structure.sql` files with version-specific comments, inconsistent formatting, and cluster metadata that pollutes git diffs.

**BetterStructureSql** uses pure Ruby introspection to generate clean schema files:

- ✅ **Clean diffs** - Only actual schema changes in version control
- ✅ **No pg_dump** - Pure Ruby database introspection
- ✅ **Deterministic** - Same input = identical output
- ✅ **Complete** - Tables, indexes, foreign keys, views, triggers, functions, extensions
- ✅ **Schema versioning** - Store and retrieve schema versions with metadata
- ✅ **Rails integration** - Drop-in replacement for `rake db:schema:dump`

## Features

### Core Features
- **Pure Ruby implementation** - No external pg_dump dependencies
- **Clean structure.sql** - Only essential schema information
- **Complete PostgreSQL support**:
  - Tables with all column types and defaults
  - Primary keys, foreign keys, and constraints
  - Indexes (including partial, unique, and expression indexes)
  - Views (including materialized views)
  - Functions and triggers
  - PostgreSQL extensions
  - Sequences
  - Custom types and enums

### Multi-File Schema Output (Optional)
- **Massive schema support** - Handle tens of thousands of tables effortlessly
- **Directory-based output** - Split schema across organized, numbered directories
- **Smart chunking** - 500 LOC per file with intelligent overflow handling
- **Better git diffs** - See only changed files, not entire schema
- **ZIP downloads** - Download complete directory structure as archive
- **Easy navigation** - Find tables quickly in `4_tables/`, triggers in `9_triggers/`, etc.

### Schema Versioning (Optional)
- Store schema versions in database with metadata
- Track PostgreSQL version, format type (SQL/Ruby), creation timestamp
- ZIP archive storage for multi-file schemas
- Configurable retention policy (keep last N versions)
- Browse and download versions via web UI (mountable Rails engine)
- Works with both `structure.sql` and `schema.rb`
- Restore from any stored version

### Web UI Engine
- **Mountable Rails Engine** - Browse schema versions in any Rails app
- **Bootstrap 5 interface** - No asset compilation required (CDN-based)
- **View schema versions** - List, view formatted schema, download raw text
- **Configurable authentication** - Integrate with Devise, Pundit, or custom auth
- **Developer onboarding** - Easy access to latest schema for new team members

### Rails Integration
- Drop-in replacement: `rake db:schema:dump` → uses BetterStructureSql
- New task: `rake db:schema:dump_better` (explicit invocation)
- New task: `rake db:schema:store` (version storage)
- Configuration via `config/initializers/better_structure_sql.rb`

### Docker Development Environment
- **Single command setup** - `docker compose up` for full environment
- **PostgreSQL included** - No local database installation needed
- **Live code reloading** - Changes reflect immediately
- **Integration app** - Test and demo environment included

## Quick Start

```ruby
# Gemfile
gem 'better_structure_sql'
```

```bash
bundle install
rails generate better_structure_sql:install
rails db:schema:dump_better
```

Your `db/structure.sql` is now clean and maintainable!

## Docker Development Environment 🐳

Get started with a fully configured development environment in seconds:

```bash
# Start PostgreSQL + Rails integration app
docker compose up

# Visit http://localhost:3000
```

See [DOCKER.md](DOCKER.md) for complete Docker documentation.

## Documentation 📚

- [Installation](docs/installation.md) - Setup and configuration
- [Configuration](docs/configuration.md) - All configuration options
- [Usage](docs/usage.md) - Rake tasks and examples
- [Schema Versions](docs/schema_versions.md) - Version storage feature
- [Multi-File Schema Output](docs/features/multi-file-schema-output/README.md) - Handle massive schemas
- [Web UI Engine](docs/features/dev-environment-docker-web-ui/README.md) - Browse versions via web interface
- [Docker Development](DOCKER.md) - Complete Docker environment guide
- [Testing](docs/testing.md) - RSpec testing guide
- [MVP Phases](docs/mvp/) - Implementation roadmap

## Example Output

**Before (pg_dump):**
```sql
--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

SET statement_timeout = 0;
SET lock_timeout = 0;
-- ... 50+ lines of SET commands and comments ...
```

**After (BetterStructureSql):**
```sql
SET client_encoding = 'UTF8';

-- Extensions
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Tables
CREATE TABLE users (
  id bigserial PRIMARY KEY,
  email varchar NOT NULL,
  created_at timestamp(6) NOT NULL,
  updated_at timestamp(6) NOT NULL
);

CREATE INDEX index_users_on_email ON users (email);

-- Schema Migrations
SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20230714030024'),
('20230714051430');

--
-- PostgreSQL database dump complete
--
```

## Configuration Example

### Single-File Output (Default)

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Single file output (default)
  config.output_path = 'db/structure.sql'

  # Replace default rake db:schema:dump
  config.replace_default_dump = true

  # Schema version storage (optional)
  config.enable_schema_versions = true
  config.schema_versions_limit = 10  # Keep last 10 versions (0 = unlimited)

  # Customize output
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true

  # Search path
  config.search_path = '"$user", public'
end
```

### Multi-File Output (For Large Schemas)

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Multi-file output - splits schema across directories
  config.output_path = 'db/schema'

  # Chunking configuration
  config.max_lines_per_file = 500        # Soft limit per file (default: 500)
  config.overflow_threshold = 1.1        # 10% overflow allowed (default: 1.1)
  config.generate_manifest = true        # Create _manifest.json (default: true)

  # Schema version storage with ZIP archives
  config.enable_schema_versions = true
  config.schema_versions_limit = 10

  # Feature toggles
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true
end
```

### Directory Structure (Multi-File Mode)

When using `config.output_path = 'db/schema'`, your schema is organized by type with numbered directories indicating load order:

```
db/schema/
├── _header.sql              # SET statements and search path
├── _manifest.json           # Metadata and load order
├── 1_extensions/
│   └── 000001.sql
├── 2_types/
│   └── 000001.sql
├── 3_sequences/
│   └── 000001.sql
├── 4_tables/
│   ├── 000001.sql          # ~500 lines per file
│   ├── 000002.sql
│   └── 000003.sql
├── 5_indexes/
│   └── 000001.sql
├── 6_foreign_keys/
│   └── 000001.sql
├── 7_views/
│   └── 000001.sql
├── 8_functions/
│   └── 000001.sql
└── 9_triggers/
    └── 000001.sql
```

**Benefits for Large Schemas**:
- ✅ Memory efficient - incremental file writing
- ✅ Git friendly - only changed files in diffs
- ✅ Easy navigation - find specific tables/triggers quickly
- ✅ ZIP downloads - complete directory as single archive
- ✅ Scalable - handles 50,000+ database objects

## Requirements

- Rails 7.0+
- PostgreSQL 12+
- Ruby 2.7+

## Migration Guides

### Migrating from schema.rb to structure.sql

If you're currently using Rails' `schema.rb` (Ruby format) and want to switch to `structure.sql` (SQL format) with BetterStructureSql, we have a comprehensive guide:

**[📖 Migration Guide: From schema.rb to structure.sql](docs/migration-guides/from-schema-rb-to-structure-sql.md)**

This guide covers:
- Why migrate from schema.rb to structure.sql
- Step-by-step migration process
- Configuration for both formats
- Switching between formats dynamically
- Comparing SQL vs Ruby schema versions
- Rollback procedures
- Best practices and troubleshooting

BetterStructureSql supports **both** `schema.rb` and `structure.sql` formats, allowing you to:
- Store versions of either format
- Switch between formats using `SCHEMA_FORMAT` environment variable
- Compare different formats in the web UI
- Migrate gradually from Ruby to SQL format

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the MIT License.
