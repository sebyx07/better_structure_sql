# Phase 4: Gemspec Optimization and Documentation

## Objective

Remove hard pg gem dependency, implement conditional gem requirements, update documentation for multi-database support, and prepare for public release.

## Deliverables

### 1. Gemspec Refactoring
**Files**:
- `better_structure_sql.gemspec`

**Current State**:
```ruby
spec.add_dependency 'pg', '>= 1.0'
spec.add_dependency 'rails', '>= 7.0'
spec.add_dependency 'rubyzip', '>= 2.0.0'
```

**Updated State**:
```ruby
# Core dependencies (required)
spec.add_dependency 'rails', '>= 7.0'
spec.add_dependency 'rubyzip', '>= 2.0.0'

# Database adapters (optional - user installs what they need)
# Documented in metadata and README

spec.metadata['optional_dependencies'] = {
  'postgresql' => 'pg >= 1.0',
  'mysql' => 'mysql2 >= 0.5',
  'sqlite' => 'sqlite3 >= 1.4'
}.to_json
```

**Tasks**:
- Remove `spec.add_dependency 'pg', '>= 1.0'`
- Update summary and description to mention multi-database support
- Add metadata for optional dependencies (documentation purpose)
- Update homepage and documentation URLs
- Add supported databases to metadata

**Updated Summary**:
```ruby
spec.summary = 'Clean schema dumps for Rails (PostgreSQL, MySQL, SQLite) without database tool dependencies'

spec.description = <<~DESC
  Pure Ruby schema dumper for Rails applications supporting PostgreSQL, MySQL, and SQLite.
  Generates clean, deterministic structure files without pg_dump, mysqldump, or sqlite3 .schema
  dependencies. Supports both single-file and multi-file output for massive schemas with tens
  of thousands of database objects. Includes schema versioning with ZIP storage and web UI.
DESC
```

### 2. Runtime Adapter Dependency Validation
**Files**:
- `lib/better_structure_sql/adapters/registry.rb`
- `lib/better_structure_sql/adapters/postgresql_adapter.rb`
- `lib/better_structure_sql/adapters/mysql_adapter.rb`
- `lib/better_structure_sql/adapters/sqlite_adapter.rb`

**Tasks**:
- Add gem availability check when adapter is initialized
- Provide helpful error messages if required gem missing
- Document which gem is needed for each adapter
- Suggest installation command in error message

**Example Implementation**:
```ruby
class PostgresqlAdapter < BaseAdapter
  def initialize(config = {})
    require 'pg'
  rescue LoadError
    raise DependencyError, <<~ERROR
      PostgreSQL adapter requires the 'pg' gem.
      Add to your Gemfile:
        gem 'pg', '>= 1.0'
      Then run: bundle install
    ERROR
  end
end

class MysqlAdapter < BaseAdapter
  def initialize(config = {})
    require 'mysql2'
  rescue LoadError
    raise DependencyError, <<~ERROR
      MySQL adapter requires the 'mysql2' gem.
      Add to your Gemfile:
        gem 'mysql2', '>= 0.5'
      Then run: bundle install
    ERROR
  end
end

class SqliteAdapter < BaseAdapter
  def initialize(config = {})
    require 'sqlite3'
  rescue LoadError
    raise DependencyError, <<~ERROR
      SQLite adapter requires the 'sqlite3' gem.
      Add to your Gemfile:
        gem 'sqlite3', '>= 1.4'
      Then run: bundle install
    ERROR
  end
end
```

### 3. README Updates
**Files**:
- `README.md`

**Sections to Add/Update**:

**Supported Databases** (new section):
```markdown
## Supported Databases

- **PostgreSQL** (9.5+) - Full feature support
- **MySQL** (8.0+) - 80% feature parity
- **SQLite** (3.35+) - 60% feature parity

See [Feature Compatibility Matrix](docs/features/multi-database-adapter-support/README.md#feature-compatibility-matrix) for details.
```

**Installation** (update):
```markdown
## Installation

Add to your Gemfile:

```ruby
# Core gem
gem 'better_structure_sql'

# Add the database adapter gem you're using:
gem 'pg'         # For PostgreSQL
gem 'mysql2'     # For MySQL
gem 'sqlite3'    # For SQLite
```

Run:
```bash
bundle install
rails generate better_structure_sql:install
```
```

**Configuration** (update with adapter examples):
```markdown
## Configuration

The gem auto-detects your database adapter. You can also configure explicitly:

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Auto-detect (default)
  config.adapter = :auto

  # PostgreSQL-specific settings
  config.postgresql.include_extensions = true
  config.postgresql.include_functions = true

  # MySQL-specific settings
  config.mysql.include_stored_procedures = true
  config.mysql.charset = 'utf8mb4'

  # SQLite-specific settings
  config.sqlite.include_triggers = true
  config.sqlite.foreign_keys_enabled = true

  # Common settings (all adapters)
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```
```

**Database-Specific Guides** (new section):
```markdown
## Database-Specific Guides

- [PostgreSQL Guide](docs/databases/postgresql.md) - Full feature documentation
- [MySQL Guide](docs/databases/mysql.md) - Type mappings and limitations
- [SQLite Guide](docs/databases/sqlite.md) - Simplified schema support
```

### 4. Database-Specific Documentation
**Files**:
- `docs/databases/postgresql.md` (new)
- `docs/databases/mysql.md` (new)
- `docs/databases/sqlite.md` (new)

**PostgreSQL Guide Content**:
- All supported features
- Extensions handling
- Custom types (ENUM, composite, domains)
- Functions and triggers (plpgsql)
- Materialized views
- Partitioned tables
- Array and JSON types
- Performance optimization tips

**MySQL Guide Content**:
- Supported features vs limitations
- Type mapping from PostgreSQL
- ENUM vs SET types
- Stored procedures syntax
- Trigger limitations
- No extensions or custom types
- JSON column usage
- Character set and collation
- Version differences (5.7 vs 8.0+)

**SQLite Guide Content**:
- Minimal feature set
- Type affinity system
- Foreign key inline requirement
- AUTOINCREMENT behavior
- No stored procedures
- Simplified triggers
- Migration challenges
- When to use SQLite (small apps, testing)

### 5. Migration Guide
**Files**:
- `docs/migration/postgresql-to-mysql.md` (new)
- `docs/migration/postgresql-to-sqlite.md` (new)

**PostgreSQL to MySQL Guide**:
- Type conversion table
- Feature mapping (what works, what doesn't)
- ENUM handling strategies
- Array to JSON conversion
- Function to stored procedure conversion
- Extension alternatives
- Performance considerations
- Testing strategies

**PostgreSQL to SQLite Guide**:
- Simplified type system
- Feature removal checklist
- CHECK constraint strategy for ENUMs
- Foreign key inline requirement
- Trigger simplification
- When SQLite is appropriate
- Performance characteristics

### 6. API Documentation
**Files**:
- All adapter files with YARD comments
- `docs/api/adapters.md` (new)
- `docs/api/extending.md` (new - how to add new adapters)

**YARD Comments**:
- Document all public methods
- Document parameters and return types
- Document exceptions raised
- Provide usage examples
- Document version requirements

**Extending Guide**:
- How to create a new adapter
- BaseAdapter interface contract
- Required methods to implement
- Normalized data structure format
- Testing requirements for new adapters
- Example: Creating a SQL Server adapter

### 7. CI/CD Updates
**Files**:
- `.github/workflows/ci.yml`

**Tasks**:
- Add MySQL to test matrix
- Add SQLite to test matrix
- Test against multiple database versions
- Test against multiple Rails versions
- Test against multiple Ruby versions
- Update badge in README for multi-database support

**Updated CI Matrix**:
```yaml
strategy:
  matrix:
    ruby: ['2.7', '3.0', '3.1', '3.2', '3.3']
    rails: ['7.0', '7.1', '8.0']
    database:
      - type: postgresql
        version: '13'
      - type: postgresql
        version: '14'
      - type: postgresql
        version: '15'
      - type: postgresql
        version: '16'
      - type: mysql
        version: '8.0'
      - type: mysql
        version: '8.4'
      - type: sqlite
        version: '3.40'
```

### 8. Update CLAUDE.md
**Files**:
- `CLAUDE.md`

**Additions** (keyword-rich context, no code):
```markdown
## Multi-Database Adapter Support

Adapter-based architecture supporting PostgreSQL, MySQL, SQLite. Each adapter implements introspection queries, SQL generation, type mapping, feature detection. BaseAdapter abstract interface, Registry factory pattern, auto-detection from ActiveRecord connection adapter_name. Conditional gem dependencies (pg, mysql2, sqlite3) validated at runtime. Database-specific configuration (PostgresqlConfig, MysqlConfig, SqliteConfig). Feature capability methods (supports_extensions?, supports_materialized_views?, supports_stored_procedures?). Normalized data structures returned from introspection. Type mapping to canonical types. Graceful feature degradation for unsupported capabilities. Version-aware feature detection per database.

### Adapter Implementations

PostgreSQL: Full feature support via pg_catalog and information_schema. Extensions, custom types (ENUM, composite, domains), materialized views, plpgsql functions, triggers, sequences, partitioning, table inheritance, array types.

MySQL: information_schema queries, mysql system tables. Stored procedures (ROUTINES), triggers, views, indexes. Type mapping: ENUM to SET, arrays to JSON, composite to JSON, SERIAL to AUTO_INCREMENT. No extensions, no materialized views, no custom domains. MySQL 8.0+ supports check constraints. Character set utf8mb4, collation utf8mb4_unicode_ci.

SQLite: sqlite_master system table, PRAGMA introspection (table_info, index_list, foreign_key_list). Type affinities (TEXT, NUMERIC, INTEGER, REAL, BLOB). Simplified triggers (no plpgsql). Foreign keys inline with CREATE TABLE. INTEGER PRIMARY KEY AUTOINCREMENT. No stored procedures, no custom types, no extensions, no sequences, no materialized views. File-based database.

### Integration Apps

integration_postgresql: Full PostgreSQL feature testing, Docker postgres:15-alpine service, pg gem, comprehensive migrations with all features.

integration_mysql: MySQL-compatible migrations, Docker mysql:8.0-alpine service, mysql2 gem, adapted schema without PostgreSQL-specific features, stored procedures, MySQL triggers.

integration_sqlite: Simplified migrations, file-based database (no Docker), sqlite3 gem, minimal feature set, inline foreign keys, CHECK constraints for enum simulation.

### Type Mappings

PostgreSQL to MySQL: ENUM→ENUM/SET, ARRAY→JSON, composite→JSON object, domain→CHECK constraint, SERIAL→AUTO_INCREMENT, UUID→CHAR(36), BYTEA→BLOB, TIMESTAMPTZ→TIMESTAMP.

PostgreSQL to SQLite: VARCHAR→TEXT, INTEGER→INTEGER, BOOLEAN→INTEGER, TIMESTAMP→TEXT (ISO8601), JSON→TEXT, ARRAY→TEXT (JSON), UUID→TEXT, BYTEA→BLOB, ENUM→TEXT + CHECK constraint, SERIAL→INTEGER PRIMARY KEY AUTOINCREMENT.

### Gemspec

No hard database adapter dependencies. Rails and rubyzip required. pg, mysql2, sqlite3 optional (user installs based on database). Runtime validation with helpful LoadError messages. Metadata documents optional dependencies for each database type.

## Keywords

Multi-database adapter pattern, BaseAdapter abstract interface, adapter registry factory, PostgreSQL adapter, MySQL adapter, SQLite adapter, auto-detect adapter, ActiveRecord connection adapter_name, conditional gem dependencies, runtime dependency validation, pg gem optional, mysql2 gem optional, sqlite3 gem optional, LoadError helpful messages, adapter capability detection, supports_extensions, supports_materialized_views, supports_stored_procedures, supports_custom_types, feature capability methods, graceful degradation, version-aware features, normalized data structures, canonical type mapping, database introspection abstraction, information_schema portability, pg_catalog PostgreSQL, mysql system tables, sqlite_master queries, PRAGMA statements SQLite, PostgresqlConfig, MysqlConfig, SqliteConfig, database-specific configuration, integration_postgresql, integration_mysql, integration_sqlite, Docker multi-database testing, CI matrix PostgreSQL MySQL SQLite, type conversion tables, migration guides PostgreSQL to MySQL, migration guides PostgreSQL to SQLite, YARD documentation adapters, extending guide new adapters, feature parity matrix, database version requirements, utf8mb4 MySQL encoding, type affinity SQLite, AUTOINCREMENT SQLite, foreign keys inline SQLite, stored procedures MySQL, simplified triggers SQLite, gemspec multi-database summary
```

### 9. Release Preparation
**Files**:
- `CHANGELOG.md` (update)
- `lib/better_structure_sql/version.rb` (bump)
- GitHub release notes

**CHANGELOG Entry**:
```markdown
## [1.0.0] - 2025-XX-XX

### Added
- Multi-database adapter support (PostgreSQL, MySQL, SQLite)
- Adapter pattern with BaseAdapter interface
- MysqlAdapter for MySQL 8.0+ support
- SqliteAdapter for SQLite 3.35+ support
- Automatic adapter detection from ActiveRecord connection
- Database-specific configuration classes
- Conditional gem dependencies (pg, mysql2, sqlite3)
- MySQL integration app with docker-compose
- SQLite integration app (file-based)
- Type mapping documentation for each database
- Migration guides (PostgreSQL to MySQL/SQLite)
- Feature compatibility matrix
- CI testing across PostgreSQL, MySQL, SQLite

### Changed
- Removed hard dependency on pg gem
- Refactored introspection to use adapter pattern
- Updated gemspec summary and description
- Enhanced error messages for missing adapter gems

### Breaking Changes
None - this is the initial public release
```

## Testing Requirements

### Documentation Tests
- README examples work correctly
- Configuration examples are valid
- Code snippets are syntactically correct
- Links to documentation files are valid
- Installation instructions work end-to-end

### CI/CD Tests
- All database adapters tested in matrix
- Multiple Ruby versions tested
- Multiple Rails versions tested
- Integration apps run successfully
- Gem builds successfully
- No hard dependency on database gems

### Installation Tests
- Install gem without database gems (should work)
- Install gem with pg gem (PostgreSQL should work)
- Install gem with mysql2 gem (MySQL should work)
- Install gem with sqlite3 gem (SQLite should work)
- Error messages helpful when adapter gem missing

## Success Criteria

- Gemspec has no hard pg dependency
- All database adapters have clear documentation
- README updated with multi-database instructions
- Migration guides complete for PostgreSQL to MySQL/SQLite
- API documentation complete with YARD comments
- CI matrix tests all databases successfully
- Installation works with any combination of adapter gems
- Error messages are helpful and actionable
- CHANGELOG accurately reflects changes
- Ready for public release

## Dependencies

### External Dependencies
- GitHub Actions (CI)
- RubyGems (for metadata)
- YARD (for API docs)
- Markdown renderers (for docs)

### Internal Dependencies
- Phase 1: Adapter infrastructure
- Phase 2: MySQL adapter
- Phase 3: SQLite adapter
- All integration apps working
- All tests passing

## Keywords

Gemspec refactoring, remove hard pg dependency, conditional gem dependencies, optional dependencies metadata, runtime dependency validation, LoadError helpful errors, gem availability check, multi-database summary, gemspec description update, supported databases metadata, README multi-database documentation, installation instructions per database, configuration examples per adapter, PostgreSQL guide, MySQL guide, SQLite guide, database-specific documentation, migration guide PostgreSQL to MySQL, migration guide PostgreSQL to SQLite, type mapping documentation, feature compatibility matrix, API documentation YARD, extending guide new adapters, BaseAdapter interface documentation, CI matrix multi-database, GitHub Actions database matrix, PostgreSQL MySQL SQLite versions, Ruby version matrix, Rails version matrix, CHANGELOG multi-database support, version bump public release, release notes, documentation tests, installation tests, error message validation, helpful dependency errors, gem build success, no hard dependencies, optional adapter gems, RubyGems publication, public release preparation
