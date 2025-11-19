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

### Schema Versioning (Optional)
- Store schema versions in database with metadata
- Track PostgreSQL version, format type (SQL/Ruby), creation timestamp
- Configurable retention policy (keep last N versions)
- Retrieve schema versions via API endpoint (example provided)
- Works with both `structure.sql` and `schema.rb`

### Rails Integration
- Drop-in replacement: `rake db:schema:dump` → uses BetterStructureSql
- New task: `rake db:schema:dump_better` (explicit invocation)
- New task: `rake db:schema:store` (version storage)
- Configuration via `config/initializers/better_structure_sql.rb`

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

## Documentation 📚

- [Installation](docs/installation.md) - Setup and configuration
- [Configuration](docs/configuration.md) - All configuration options
- [Usage](docs/usage.md) - Rake tasks and examples
- [Schema Versions](docs/schema_versions.md) - Version storage feature
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

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
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

## Requirements

- Rails 7.0+
- PostgreSQL 12+
- Ruby 2.7+

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the MIT License.
