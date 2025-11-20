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

> **⚠️ Beta Notice**: Version 0.1.0 is feature-complete and production-ready for **PostgreSQL**. Multi-database support (MySQL, SQLite) is implemented but considered experimental. APIs are stable but may see minor refinements before v1.0. We welcome feedback and contributions!

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

| Feature | PostgreSQL 12+ | MySQL 8.0+ | SQLite 3.35+ |
|---------|----------------|------------|--------------|
| **Tables & Columns** | ✅ Full | ✅ Full | ✅ Full |
| **Indexes** | ✅ btree, gin, gist, hash, brin | ✅ btree, hash, fulltext | ✅ btree |
| **Foreign Keys** | ✅ All actions | ✅ All actions | ✅ Inline with CREATE TABLE |
| **Unique Constraints** | ✅ | ✅ | ✅ |
| **Check Constraints** | ✅ | ✅ (8.0.16+) | ✅ |
| **Extensions** | ✅ pgcrypto, uuid-ossp, pg_trgm, etc. | ❌ | ❌ (PRAGMA settings instead) |
| **Custom Types (ENUM)** | ✅ CREATE TYPE | ❌ (inline ENUM/SET) | ❌ (CHECK constraints) |
| **Sequences** | ✅ CREATE SEQUENCE | ❌ (AUTO_INCREMENT) | ❌ (AUTOINCREMENT) |
| **Views** | ✅ Regular views | ✅ Regular views | ✅ Regular views |
| **Materialized Views** | ✅ | ❌ | ❌ |
| **Functions** | ✅ plpgsql, sql | ✅ Stored procedures | ❌ |
| **Triggers** | ✅ BEFORE/AFTER/INSTEAD OF | ✅ BEFORE/AFTER | ✅ BEFORE/AFTER |
| **Partitioned Tables** | ✅ RANGE/LIST/HASH | ❌ | ❌ |
| **Domains** | ✅ | ❌ | ❌ |

### Getting Started by Database

- **PostgreSQL**: [Installation →](https://www.postgresql.org/download/) | [Rails Guide →](https://guides.rubyonrails.org/configuring.html#configuring-a-postgresql-database)
- **MySQL**: [Installation →](https://dev.mysql.com/downloads/mysql/) | [Rails Guide →](https://guides.rubyonrails.org/configuring.html#configuring-a-mysql-or-mariadb-database)
- **SQLite**: [Installation →](https://www.sqlite.org/download.html) | [Rails Guide →](https://guides.rubyonrails.org/configuring.html#configuring-a-sqlite3-database)

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
- **Massive schema support** - Designed to handle tens of thousands of database objects
- **Directory-based output** - Split schema across organized, numbered directories
- **Smart chunking** - 500 LOC per file (configurable) with intelligent overflow handling
- **Better git diffs** - See only changed files, not entire schema
- **ZIP downloads** - Download complete directory structure as archive
- **Easy navigation** - Find tables quickly in `05_tables/`, triggers in `09_triggers/`, etc.

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
- Drop-in replacement: `rake db:schema:dump` → uses BetterStructureSql (when enabled)
- Configuration via `config/initializers/better_structure_sql.rb`
- **Rake Tasks**:
  - `db:schema:dump_better` - Explicitly dump schema using BetterStructureSql
  - `db:schema:load_better` - Load schema (supports both file and directory mode)
  - `db:schema:store` - Store current schema as a version in database
  - `db:schema:versions` - List all stored schema versions
  - `db:schema:cleanup` - Remove old versions based on retention limit
  - `db:schema:restore[VERSION_ID]` - Restore database from specific version

### Docker Development Environment
- **Single command setup** - `docker compose up` for full environment
- **PostgreSQL included** - No local database installation needed
- **Live code reloading** - Changes reflect immediately
- **Integration app** - Test and demo environment included

## 🚀 Quick Start

```ruby
# Gemfile
gem 'better_structure_sql'
gem 'pg'  # For PostgreSQL (or 'mysql2' for MySQL, or 'sqlite3' for SQLite)
```

**Database adapter is auto-detected** from your `ActiveRecord::Base.connection.adapter_name`. No manual configuration needed!

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
- [Troubleshooting](docs/usage.md#troubleshooting) - Common issues and solutions
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

  # Replace default rake db:schema:dump (opt-in, default: false)
  # When false, use explicit tasks: rails db:schema:dump_better
  config.replace_default_dump = false
  config.replace_default_load = false

  # Schema version storage (optional)
  config.enable_schema_versions = true
  config.schema_versions_limit = 10  # Keep last 10 versions (0 = unlimited)

  # Customize output (feature toggles)
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true
  config.include_materialized_views = true  # PostgreSQL only
  config.include_domains = true             # PostgreSQL only
  config.include_sequences = true           # PostgreSQL only
  config.include_custom_types = true        # PostgreSQL ENUM, MySQL ENUM/SET
  config.include_rules = false              # Experimental
  config.include_comments = false           # Database object comments

  # Search path and schema filtering
  config.search_path = '"$user", public'
  config.schemas = ['public']               # Which schemas to dump
end
```

### 📁 Multi-File Output (Recommended for Large Projects)

> **💡 Recommended:** Use `db/schema` directory mode for projects with 100+ tables for better git diffs, easier navigation, and AI-friendly organization.

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

  # Feature toggles (same as single-file mode)
  config.include_extensions = true
  config.include_functions = true
  config.include_triggers = true
  config.include_views = true
  config.include_materialized_views = true
  config.include_domains = true
  config.include_sequences = true
  config.include_custom_types = true

  # Formatting options
  config.indent_size = 2                    # SQL indentation (default: 2)
  config.add_section_spacing = true         # Add blank lines between sections
  config.sort_tables = true                 # Sort tables alphabetically
end
```

### 📂 Directory Structure (Multi-File Mode)

When using `config.output_path = 'db/schema'`, your schema is organized by type with numbered directories indicating load order:

```
db/schema/
├── _header.sql              # SET statements and search path
├── _manifest.json           # Metadata and load order
├── 01_extensions/
│   └── 000001.sql
├── 02_types/
│   └── 000001.sql
├── 03_functions/
│   └── 000001.sql
├── 04_sequences/
│   └── 000001.sql
├── 05_tables/
│   ├── 000001.sql          # ~500 lines per file
│   ├── 000002.sql
│   └── 000003.sql
├── 06_indexes/
│   └── 000001.sql
├── 07_foreign_keys/
│   └── 000001.sql
├── 08_views/
│   └── 000001.sql
├── 09_triggers/
│   └── 000001.sql
└── 10_migrations/
    └── 000001.sql
```

**Benefits for Large Schemas**:
- ✅ Memory efficient - incremental file writing
- ✅ Git friendly - only changed files in diffs
- ✅ Easy navigation - find specific tables in `05_tables/`, triggers in `09_triggers/`, etc.
- ✅ ZIP downloads - complete directory as single archive
- ✅ Scalable - handles 50,000+ database objects
- ✅ AI-friendly - 500-line chunks work better with LLM context windows

**Manifest File (_manifest.json)**:

The manifest tracks metadata and provides load order information:

```json
{
  "version": "1.0",
  "total_files": 11,
  "total_lines": 2345,
  "max_lines_per_file": 500,
  "directories": {
    "01_extensions": { "files": 1, "lines": 3 },
    "02_types": { "files": 1, "lines": 13 },
    "03_functions": { "files": 1, "lines": 332 },
    "04_sequences": { "files": 1, "lines": 289 },
    "05_tables": { "files": 2, "lines": 979 },
    "06_indexes": { "files": 1, "lines": 397 },
    "07_foreign_keys": { "files": 1, "lines": 67 },
    "08_views": { "files": 1, "lines": 217 },
    "09_triggers": { "files": 1, "lines": 35 },
    "10_migrations": { "files": 1, "lines": 13 }
  }
}
```

This example shows a real schema with 2,345 lines split across 11 files. The `05_tables` directory has 2 files because the tables exceed the 500-line limit.

## 📝 Usage & Rake Tasks

### Core Schema Tasks

```bash
# Dump schema using BetterStructureSql (explicit)
rails db:schema:dump_better

# Load schema from file or directory
rails db:schema:load_better
```

### Schema Versioning Tasks

**Store Current Schema**
```bash
# Store the current schema as a version in the database
rails db:schema:store
```

This command:
- Reads your current `db/structure.sql` or `db/schema` directory
- Stores it in the `better_structure_sql_schema_versions` table
- Includes metadata: format type, output mode, database version, file count
- For multi-file schemas, creates a ZIP archive of all files
- Automatically manages retention (keeps last N versions based on config)

**List Stored Versions**
```bash
# View all stored schema versions
rails db:schema:versions
```

Output example:
```
Total versions: 3

ID     Format  Mode          Files   PostgreSQL      Created              Size
-----------------------------------------------------------------------------------------------
3      sql     multi_file    12      15.3            2025-01-15 10:30:22  56.42 KB
2      sql     single_file   1       15.3            2025-01-14 15:20:10  45.21 KB
1      sql     single_file   1       15.2            2025-01-13 09:45:33  44.03 KB
```

The multi-file mode example shows 12 files across 10 directories (extensions, types, functions, sequences, tables, indexes, foreign_keys, views, triggers, migrations) stored as a ZIP archive.

**Restore from Version**
```bash
# Restore database from a specific version
rails db:schema:restore[5]

# Or using environment variable
VERSION_ID=5 rails db:schema:restore
```

**Cleanup Old Versions**
```bash
# Remove old versions based on retention limit
rails db:schema:cleanup
```

### Web UI Engine

Mount the web interface to browse schema versions:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # With authentication (recommended for production)
  authenticate :user, ->(user) { user.admin? } do
    mount BetterStructureSql::Engine, at: '/schema_versions'
  end

  # Or without authentication (development only)
  mount BetterStructureSql::Engine, at: '/schema_versions' if Rails.env.development?
end
```

Access at `http://localhost:3000/schema_versions` to:
- View list of up to 100 most recent schema versions (pagination-ready)
- Browse formatted schema content with syntax highlighting (for files <200KB)
- Download raw SQL/Ruby schema files as text
- Download ZIP archives for multi-file schemas
- View manifest metadata for multi-file schemas
- Stream large files efficiently (>2MB) without memory issues
- Compare database versions and formats

**Authentication Examples**:

```ruby
# Devise with admin check
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/admin/schema'
end

# Custom constraint class
class AdminConstraint
  def matches?(request)
    user = request.env['warden']&.user
    user&.admin?
  end
end

constraints AdminConstraint.new do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end

# Environment-based
if Rails.env.production?
  # Add your production auth here
else
  mount BetterStructureSql::Engine, at: '/schema_versions'
end
```

### Automatic Schema Storage Workflow

**Option 1: After Each Migration (Recommended)**
```bash
# Run migration and store schema version
rails db:migrate && rails db:schema:store
```

**Option 2: Git Hooks**
```bash
# .git/hooks/post-merge
#!/bin/bash
if git diff HEAD@{1} --name-only | grep -q "db/migrate"; then
  echo "Migrations detected, storing schema version..."
  rails db:schema:store
fi
```

**Option 3: CI/CD Pipeline**
```yaml
# .github/workflows/deploy.yml
- name: Run migrations and store schema
  run: |
    rails db:migrate
    rails db:schema:store
```

## 📋 Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **Ruby** | 2.7+ | Tested up to Ruby 3.4.7 |
| **Rails** | 7.0+ | Works with Rails 8.1.1+ |
| **rubyzip** | ≥ 2.0.0 | Required for ZIP archive support |
| **Database Adapter** | | |
| `pg` | ≥ 1.0 | **Required dependency**. Works with PostgreSQL 12+ |
| `mysql2` | ≥ 0.5 | Optional. For MySQL 8.0+ (experimental) |
| `sqlite3` | ≥ 1.4 | Optional. For SQLite 3.35+ (experimental) |

**Note**: The gem currently requires the `pg` gem as a dependency. Multi-database support (MySQL, SQLite) is implemented but requires manual gem installation. Future versions may make database adapters optional.

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

## 📊 Project Stats

**Codebase Metrics** (as of v0.1.0):
- **47 Ruby files** in `lib/` (~5,296 total lines)
- **25 test files** in `spec/` (~3,022 lines)
- **8 adapter files** (PostgreSQL, MySQL, SQLite, Registry, Configs)
- **13 SQL generators** (Tables, Indexes, Functions, Triggers, Views, etc.)
- **9 introspection modules** (Extensions, Types, Tables, Indexes, Foreign Keys, etc.)
- **3 integration apps** (PostgreSQL, MySQL, SQLite) with Docker support
- **React documentation site** deployed to GitHub Pages

**Test Coverage**: Comprehensive RSpec test suite with unit and integration tests across all major components.

**Real-World Example**: The integration app generates a multi-file schema with:
- 11 SQL files across 10 directories
- 2,345 total lines of SQL
- Complete PostgreSQL feature coverage (extensions, types, functions, triggers, materialized views)

**Production Status**:
- ✅ **PostgreSQL**: Fully implemented and tested (primary focus)
- ✅ **Multi-file output**: Complete with ZIP storage and streaming
- ✅ **Schema versioning**: Full CRUD with web UI
- ✅ **Rails integration**: Drop-in replacement for default tasks
- 🧪 **MySQL**: Adapter implemented, integration app available (experimental)
- 🧪 **SQLite**: Adapter implemented, basic testing (experimental)

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
