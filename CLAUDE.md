# BetterStructureSql - Claude Context

Project context and development guidelines for AI-assisted development.

## Project Purpose

Ruby gem that generates clean PostgreSQL schema dumps for Rails applications without pg_dump dependency. Replaces noisy structure.sql files with deterministic, maintainable output using pure Ruby database introspection.

## Core Problems Solved

**pg_dump issues**:
- Version-specific comments pollute git diffs
- Inconsistent output across PostgreSQL versions
- Cluster metadata creates noise
- External binary dependency
- Non-deterministic formatting

**Solution approach**:
- Pure Ruby implementation
- Query information_schema and pg_catalog directly
- Deterministic sorted output
- Clean SQL generation
- Optional schema versioning with retention management

## Component Architecture

### Core Components

**Configuration** - Centralized settings management with validation
- Output paths, search paths
- Feature toggles (extensions, functions, triggers, views)
- Schema versioning settings (enabled, retention limit)

**Introspection** - PostgreSQL metadata extraction
- Extensions from pg_extension
- Custom types and enums from pg_type
- Tables and columns from information_schema
- Indexes from pg_indexes
- Foreign keys from pg_constraint
- Views from pg_views
- Functions from pg_proc
- Triggers from pg_trigger

**Generators** - SQL statement creation (one per object type)
- ExtensionGenerator - CREATE EXTENSION statements
- TypeGenerator - CREATE TYPE for enums and domains
- TableGenerator - CREATE TABLE with columns and constraints
- IndexGenerator - CREATE INDEX with all variants
- ForeignKeyGenerator - ALTER TABLE ADD CONSTRAINT
- ViewGenerator - CREATE VIEW and MATERIALIZED VIEW
- FunctionGenerator - CREATE FUNCTION with plpgsql/sql
- TriggerGenerator - CREATE TRIGGER with timing and events

**Dumper** - Orchestration and file output
- Coordinates introspection
- Invokes generators in dependency order
- Formats output sections
- Writes structure.sql
- Triggers schema version storage

**Formatter** - Consistent SQL formatting
- Whitespace normalization
- Indentation management
- Keyword capitalization
- Section spacing

**SchemaVersions** - Version storage and retrieval
- Store schema snapshots in database
- Track PostgreSQL version and format type
- Manage retention with configurable limits
- Provide query interface for versions

**DependencyResolver** - Object ordering
- Build dependency graph
- Topological sort for correct order
- Handle views depending on tables
- Handle functions used by triggers

### Rails Integration

**Railtie** - Rails framework hooks
- Rake task registration
- Initializer loading
- Optional override of default schema dump

**Generator** - Installation scaffolding
- Create initializer configuration file
- Generate migration for schema_versions table
- Setup instructions

**Rake Tasks** - Command interface
- db:schema:dump_better - explicit dump
- db:schema:dump - replacement when configured
- db:schema:store - store version
- db:schema:versions - list versions
- db:schema:cleanup - manual retention cleanup

## Development Principles

### SOLID Principles

**Single Responsibility**
- Each generator handles exactly one PostgreSQL object type
- Introspection only queries metadata, never generates SQL
- Dumper orchestrates but delegates all generation
- Formatter handles presentation, not logic

**Open/Closed**
- New generators added without modifying existing code
- Configuration extensible via hash-like interface
- Hooks for before/after dump customization

**Liskov Substitution**
- All generators inherit from Base and implement generate(object)
- Interchangeable without affecting Dumper

**Interface Segregation**
- Small focused interfaces per component
- Generators only need generate method
- Introspection methods independently callable

**Dependency Inversion**
- Depend on abstractions (ActiveRecord connection, not specific adapter)
- Configuration injected, not global
- Generators receive data, not database connection

### Code Quality Standards

**TDD Approach**
- Write failing test first
- Implement minimum code to pass
- Refactor with confidence
- Maintain test coverage above 95%

**Test Types**
- Unit tests: Individual classes in isolation
- Integration tests: Full dump workflow with real database
- Comparison tests: Output vs pg_dump validation
- Performance tests: Benchmark against targets

**Code Organization**
- Small methods (5-10 lines preferred)
- Clear method names describing intent
- Avoid god objects and long parameter lists
- Extract complex logic to private methods

**Naming Conventions**
- Classes: Nouns describing objects (TableGenerator, SchemaVersion)
- Methods: Verbs describing actions (fetch_tables, generate_index)
- Variables: Descriptive nouns (table_name, foreign_keys)
- Boolean methods: Predicate names (supports_materialized_views?)

### Code Style

**Readability First**
- Explicit over clever
- Comments explain why, not what
- Descriptive variable names
- Consistent formatting via Rubocop

**Error Handling**
- Fail fast with informative messages
- Rescue specific exceptions, not generic
- Provide actionable error context
- Log warnings for degraded features

**Performance Awareness**
- Batch database queries where possible
- Cache repeated introspection within dump session
- Use database indexes for metadata queries
- Stream large results, avoid loading all into memory

**Security**
- Parameterized SQL queries prevent injection
- Never execute user-provided SQL
- Structure-only dumps, no data
- Secure file permissions on output

## PostgreSQL Features Supported

### Essential
- Tables with all column types
- Primary keys
- Foreign keys with actions (CASCADE, RESTRICT, SET NULL)
- Indexes (btree, gin, gist, hash)
- Unique constraints
- Check constraints
- NOT NULL constraints
- DEFAULT values
- Extensions (pgcrypto, uuid-ossp, hstore, pg_trgm, etc)
- Sequences
- Custom types (enums, domains)

### Advanced
- Views (regular and materialized)
- Functions (plpgsql, sql languages)
- Triggers (BEFORE, AFTER, INSTEAD OF)
- Partial indexes with WHERE clauses
- Expression indexes
- Multi-column indexes
- Partitioned tables (RANGE, LIST, HASH)
- Table inheritance
- Comments on database objects

### Ordering Requirements
1. Extensions (needed by types and functions)
2. Custom types (needed by tables)
3. Sequences (needed by defaults)
4. Tables (dependency-ordered)
5. Indexes (after tables)
6. Foreign keys (after all tables exist)
7. Views (dependency-ordered, after tables)
8. Functions (dependency-ordered)
9. Triggers (after functions and tables)
10. Schema migrations INSERT
11. Search path SET

## Schema Versioning Feature

### Storage Model
- Database table: better_structure_sql_schema_versions
- Columns: id, content (text), pg_version (varchar), format_type (varchar), created_at (timestamp)
- Index on created_at DESC for efficient queries
- Works with both structure.sql and schema.rb formats

### Retention Management
- Configurable limit (default: 10, 0 = unlimited)
- Automatic cleanup on store
- Keep N most recent versions
- Manual cleanup via rake task

### Use Cases
- Developer onboarding (download latest schema)
- Schema comparison (diff between versions)
- Rollback capability (restore previous schema)
- Audit trail (track schema evolution)
- API endpoint (authenticated access for developers)

## Testing Strategy

### Test Database
- Use Rails dummy app with complex schema
- 15+ tables with realistic relationships
- All PostgreSQL features represented
- Extensions, types, views, functions, triggers
- Partitioned and inherited tables

### Comparison Testing
- Generate schema with pg_dump
- Generate schema with BetterStructureSql
- Normalize both outputs
- Compare object lists (tables, indexes, etc)
- Verify BetterStructureSql output is cleaner but complete

### Edge Cases
- Empty database
- Missing schema_migrations table
- Circular dependencies
- Complex column types (arrays, jsonb, hstore)
- Large schemas (500+ tables)
- Multiple schemas
- Reserved SQL keywords in names

### Performance Targets
- 100 tables: under 5 seconds
- 500 tables: under 20 seconds
- Memory usage: under 100MB increase
- Deterministic: identical output on repeated runs

## Configuration Philosophy

**Convention over Configuration**
- Sensible defaults for 90% use cases
- Opt-in for advanced features
- Minimal required configuration

**Configuration Options**
- Core: output_path, search_path, replace_default_dump
- Features: include_extensions, include_functions, include_triggers, include_views
- Versioning: enable_schema_versions, schema_versions_limit
- Formatting: indent_size, add_section_spacing, sort_tables

**Environment-Specific**
- Allow per-environment configuration
- Development: verbose, store versions
- Production: minimal, no storage
- Test: fast, skip optional features

## Implementation Phases

### Phase 1: Foundation
- Core introspection and generation
- Tables, indexes, foreign keys, extensions
- Basic Rails integration
- Unit and integration tests

### Phase 2: Versioning
- Schema version storage model
- Retention management
- Rake tasks for version operations
- API endpoint documentation

### Phase 3: Advanced
- Views and materialized views
- Functions and triggers
- Partitioned tables
- Table inheritance
- Dependency resolution
- Performance optimization

## Development Workflow

**TDD Cycle**
1. Write failing test for feature
2. Implement minimum code to pass
3. Run full test suite
4. Refactor for clarity and performance
5. Commit with descriptive message

**Code Review Focus**
- Single responsibility maintained
- Tests cover edge cases
- Performance implications considered
- Documentation updated
- Error messages helpful

**Documentation Requirements**
- YARD comments on public methods
- README examples for features
- Inline comments for complex logic
- Update phase documents with progress

## Common Patterns

### Generator Pattern
Each PostgreSQL object type has dedicated generator class implementing:
- `generate(object)` - returns SQL string
- Private helper methods for object-specific logic
- Inherits from Generators::Base

### Query Batching
Fetch all instances of object type in single query, not N+1:
- fetch_all_indexes instead of fetch_indexes(table) repeatedly
- Build hash lookup by table_name
- Single pass through results

### Graceful Degradation
Feature detection before attempting queries:
- Check PostgreSQL version for feature support
- Rescue specific errors and log warnings
- Return empty arrays for unsupported features
- Document minimum version requirements

### Dependency Injection
Pass dependencies as parameters:
- Configuration injected to constructors
- Database connection passed explicitly
- Avoid global state where possible
- Enable testing with mocks

## Web UI and Development Environment

### Rails Engine (Mountable)
**Location**: Integrated into gem at `app/`, `lib/better_structure_sql/engine.rb`
**Purpose**: Web interface for browsing stored schema versions
**Routes**: `/better_structure_sql/schema_versions` (configurable mount point)
**Actions**: index (list), show (formatted view), raw (text download)
**Layout**: Bootstrap 5 from CDN (no asset compilation)
**Icons**: Bootstrap Icons from CDN
**Authentication**: Configurable hook in ApplicationController (Devise, Pundit, custom)
**Authorization**: Document patterns for admin-only access
**Content-Type**: HTML for views, text/plain for raw downloads
**Pagination**: Support for large version lists

### Docker Development Environment
**Services**: PostgreSQL (internal only), Rails web (port 3000)
**Volumes**: postgres_data (persistence), gem source mount (live reload)
**Integration app**: test/dummy or integration/ directory
**Configuration**: Custom database.yml, custom BetterStructureSql initializer
**Format support**: Both structure.sql and schema.rb
**Seed data**: Sample schema versions with varied content
**Multi-database prep**: Architecture supports future MySQL, SQLite (PostgreSQL only currently)
**Environment variables**: DB_ADAPTER, DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASSWORD, DATABASE_URL
**Dockerfile**: Ruby 3.2-alpine, postgresql-dev, build-base, nodejs
**docker-compose.yml**: Service orchestration, health checks, networking

### Engine Authentication Patterns
**Primary approach**: Route constraints in config/routes.rb using `authenticate` or `constraints`
**Devise integration**: `authenticate :user, ->(user) { user.admin? } do ... end`
**Custom constraint**: Class with `matches?(request)` method
**Alternative**: Controller-level via `class_eval` on ApplicationController
**No auth**: Direct mount (development/testing only)
**Documentation**: Multiple constraint examples in feature docs

### Configuration Flexibility
**Database**: Environment-specific database.yml, ENV overrides
**Gem settings**: Initializer for format, versioning, retention
**Engine mount**: Custom path in routes.rb
**Format selection**: Toggle between sql/rb output
**Feature flags**: Extensions, views, functions, triggers toggles
**Future support**: Adapter detection for multi-database compatibility

## Keywords for Context

PostgreSQL, schema dump, structure.sql, pg_dump replacement, Rails gem, database introspection, information_schema, pg_catalog, SQL generation, schema versioning, deterministic output, clean diffs, version control, database migrations, schema management, ActiveRecord, pure Ruby, TDD, SOLID principles, single responsibility, dependency injection, topological sort, foreign keys, indexes, views, triggers, functions, extensions, custom types, enums, partitioned tables, table inheritance, Rails integration, rake tasks, Railtie, configuration management, retention policy, metadata extraction, comparison testing, performance optimization, batch queries, dependency resolution, graceful degradation, error handling, code quality, test coverage, dummy application, integration testing, unit testing, RSpec, factory_bot, database_cleaner, continuous integration, GitHub Actions, semantic versioning, open source, MIT license, Rails Engine, mountable engine, Bootstrap 5, CDN assets, web UI, schema browser, Docker, docker-compose, PostgreSQL container, volume persistence, development environment, integration app, authentication patterns, Devise, Pundit, authorization, configurable routes, multi-database architecture, environment variables, database.yml customization, initializer configuration, format selection, live reload, asset-free deployment
