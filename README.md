<div align="center">

# 🗄️ BetterStructureSql

### Clean, maintainable database schema dumps for Rails
**PostgreSQL • MySQL • SQLite**

[![Gem Version](https://badge.fury.io/rb/better_structure_sql.svg)](https://badge.fury.io/rb/better_structure_sql)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/rails-%3E%3D%207.0-red.svg)](https://rubyonrails.org/)

**[📚 Documentation](https://sebyx07.github.io/better_structure_sql/)** • **[🐙 GitHub](https://github.com/sebyx07/better_structure_sql)** • **[💎 RubyGems](https://rubygems.org/gems/better_structure_sql)**

---

</div>

> **⚠️ Beta Notice**: This gem is currently in beta (version 0.1.0). APIs may change between releases until v1.0. We welcome feedback and contributions!

## ✨ Why BetterStructureSql?

Rails' database dump tools (`pg_dump`, `mysqldump`, etc.) create noisy `structure.sql` files with version-specific comments, inconsistent formatting, and metadata that pollutes git diffs.

**BetterStructureSql** uses pure Ruby introspection to generate clean schema files:

<table>
<tr>
<td width="50%">

### 🎯 Core Benefits

- ✅ **Clean diffs** - Only actual schema changes
- ✅ **No external tools** - Pure Ruby introspection
- ✅ **Multi-database** - PostgreSQL, MySQL, SQLite
- ✅ **Deterministic** - Same input = identical output

</td>
<td width="50%">

### 🚀 Advanced Features

- ✅ **Complete coverage** - Tables, views, triggers, functions
- ✅ **Schema versioning** - Store & retrieve versions
- ✅ **Multi-file output** - Handle massive schemas
- ✅ **Rails integration** - Drop-in replacement

</td>
</tr>
</table>

---

## 🗃️ Database Support

| Database | Version | Feature Coverage | Highlights |
|----------|---------|------------------|------------|
| **PostgreSQL** | 12+ | 🟢 **100%** | Extensions, materialized views, functions, triggers, custom types |
| **MySQL** | 8.0+ | 🟡 **80%** | Stored procedures, triggers, views, indexes |
| **SQLite** | 3.35+ | 🟡 **60%** | Lightweight schemas, triggers, views |

📖 See [Feature Compatibility Matrix](docs/features/multi-database-adapter-support/README.md#feature-compatibility-matrix) for detailed comparison.

## Features

### Core Features
- **Pure Ruby implementation** - No external tool dependencies (pg_dump, mysqldump, sqlite3 CLI)
- **Multi-database adapter pattern** - Auto-detects database type from ActiveRecord connection
- **Clean structure.sql** - Only essential schema information
- **Complete database support**:
  - Tables with all column types and defaults
  - Primary keys, foreign keys, and constraints
  - Indexes (including partial, unique, and expression indexes)
  - Views (and materialized views for PostgreSQL)
  - Functions/stored procedures and triggers (database-dependent)
  - Extensions (PostgreSQL)
  - Sequences (PostgreSQL)
  - Custom types and enums (PostgreSQL, MySQL SET/ENUM)

### Multi-File Schema Output (Optional)
- **Massive schema support** - Handle tens of thousands of tables effortlessly
- **Directory-based output** - Split schema across organized, numbered directories
- **Smart chunking** - 500 LOC per file with intelligent overflow handling
- **Better git diffs** - See only changed files, not entire schema
- **ZIP downloads** - Download complete directory structure as archive
- **Easy navigation** - Find tables quickly in `4_tables/`, triggers in `9_triggers/`, etc.

### Schema Versioning (Optional)
- Store schema versions in database with metadata
- Track database type and version, format type (SQL/Ruby), creation timestamp
- ZIP archive storage for multi-file schemas
- Configurable retention policy (keep last N versions)
- Browse and download versions via web UI (mountable Rails engine)
- Works with both `structure.sql` and `schema.rb`
- Works across all database types (PostgreSQL, MySQL, SQLite)
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

## 🚀 Quick Start

```ruby
# Gemfile
gem 'better_structure_sql'
gem 'pg'  # or 'mysql2' or 'sqlite3'
```

```bash
bundle install
rails generate better_structure_sql:install
rails db:schema:dump_better
```

**🎉 Your `db/structure.sql` is now clean and maintainable!**

## Docker Development Environment 🐳

Get started with a fully configured development environment in seconds:

```bash
# Start PostgreSQL + Rails integration app
docker compose up

# Visit http://localhost:3000
```

See [DOCKER.md](DOCKER.md) for complete Docker documentation.

## Documentation 📚

### 🌐 Documentation Website
**[Visit the full documentation site →](https://sebyx07.github.io/better_structure_sql/)**

Interactive documentation with tutorials, database-specific guides, and real-world examples showing how to use SQL databases to their fullest with BetterStructureSql. Features include:
- Step-by-step tutorials for PostgreSQL, MySQL, and SQLite
- Real-world examples using advanced database features (triggers, views, functions)
- Production deployment guides with automatic schema versioning
- API reference and configuration examples
- AI-friendly multi-file schema benefits

### General Documentation
- [Installation](docs/installation.md) - Setup and configuration
- [Configuration](docs/configuration.md) - All configuration options
- [Usage](docs/usage.md) - Rake tasks and examples
- [Schema Versions](docs/schema_versions.md) - Version storage feature
- [Multi-File Schema Output](docs/features/multi-file-schema-output/README.md) - Handle massive schemas
- [Web UI Engine](docs/features/dev-environment-docker-web-ui/README.md) - Browse versions via web interface
- [Docker Development](DOCKER.md) - Complete Docker environment guide
- [Testing](docs/testing.md) - RSpec testing guide
- [MVP Phases](docs/mvp/) - Implementation roadmap

### Multi-Database Support
- [Multi-Database Architecture](docs/features/multi-database-adapter-support/README.md) - Overview and feature matrix
- [Database Adapters Architecture](docs/features/multi-database-adapter-support/architecture.md) - Technical deep dive
- [Implementation Phases](docs/features/multi-database-adapter-support/plan/) - Phased rollout plan

## 📊 Example Output

<table>
<tr>
<td width="50%">

### ❌ Before (pg_dump)

```sql
--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
-- ... 50+ more lines ...
```

**😕 Issues:**
- Version-specific comments
- Noisy SET commands
- Non-deterministic output
- Hard to review diffs

</td>
<td width="50%">

### ✅ After (BetterStructureSql)

```sql
SET client_encoding = 'UTF8';

-- Extensions
CREATE EXTENSION IF NOT EXISTS plpgsql
  WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pgcrypto
  WITH SCHEMA public;

-- Tables
CREATE TABLE users (
  id bigserial PRIMARY KEY,
  email varchar NOT NULL,
  created_at timestamp(6) NOT NULL,
  updated_at timestamp(6) NOT NULL
);

CREATE INDEX index_users_on_email
  ON users (email);
```

**🎯 Benefits:**
- Clean, minimal output
- Deterministic
- Easy to review
- Version control friendly

</td>
</tr>
</table>

## ⚙️ Configuration

### 📄 Single-File Output (Default)

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

### 📁 Multi-File Output (For Large Schemas)

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

### 📂 Directory Structure (Multi-File Mode)

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

## 📋 Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **Ruby** | 2.7+ | Tested up to Ruby 3.4.7 |
| **Rails** | 7.0+ | Works with Rails 8.1.1+ |
| **Database Adapter** | | Choose one: |
| `pg` | ≥ 1.0 | For PostgreSQL 12+ |
| `mysql2` | ≥ 0.5 | For MySQL 8.0+ |
| `sqlite3` | ≥ 1.4 | For SQLite 3.35+ |

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

---

## 🤝 Contributing

We welcome contributions! Bug reports and pull requests are welcome on [GitHub](https://github.com/sebyx07/better_structure_sql).

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run the tests (`bundle exec rspec`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## 📄 License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

**Made with ❤️ by [sebyx07](https://github.com/sebyx07) and [contributors](https://github.com/sebyx07/better_structure_sql/graphs/contributors)**

⭐ **Star this repo if you find it useful!** ⭐
