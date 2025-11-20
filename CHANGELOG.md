# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

## [0.2.1] - 2025-11-20

### Changed
- Improved schema version web UI with content hash display (first 8 characters)
- Increased view limit for better visibility of stored schema versions

## [0.2.0] - 2025-11-20

### Added
- **Database comments support** - COMMENT ON statements for PostgreSQL and MySQL
  - Comments on tables, columns, indexes, views, functions, and triggers
  - CommentGenerator for generating COMMENT ON SQL statements
  - CommentIntrospector for querying pg_description and information_schema
  - Configurable via `include_comments` option (enabled by default)
  - 10_comments directory in multi-file output with load order after triggers
  - Full test coverage for PostgreSQL and MySQL comment introspection
- **Hash-based schema version deduplication** - Automatic duplicate detection using MD5 content hashing
  - `content_hash` column (VARCHAR 32) stores MD5 hexdigest of schema content
  - Automatic skip when schema unchanged between storage attempts
  - StoreResult value object for skip/store state communication
  - Filesystem cleanup: delete multi-file directories after ZIP storage
  - Enhanced rake task output showing skip reason or stored confirmation with hash
  - `db:schema:versions` task now displays first 8 characters of content hash
  - Content size and line count automatic tracking
  - Streaming file reads (4MB chunks) for memory-efficient hash calculation
  - Integration with retention management (cleanup only on actual storage)
  - 29 new tests for deduplication workflow (all 355 tests passing)

### Changed
- **BREAKING**: Schema versions table requires `content_hash` column
  - Run `rails generate better_structure_sql:migration` to add column
  - Existing versions backfilled with calculated MD5 hash during migration
- `SchemaVersions.store_current` now returns `StoreResult` instead of `SchemaVersion`
  - Use `result.stored?` or `result.skipped?` to check operation type
  - Access version via `result.version` when stored
- `SchemaVersions.store` now requires `content_hash:` parameter
- `SchemaVersion.latest` changed from scope to class method (returns record, not Relation)
- Multi-file directories automatically cleaned up after ZIP archive creation
- Integration apps configured to use multi-file schema dumps by default
- Migration numbering scheme changed to support comments directory (20 directories)

### Fixed
- MySQL compatibility: Removed IF NOT EXISTS from index and type creation
- Hash calculation now excludes manifest.json to avoid circular dependencies
- FileWriter properly maps comments directory to correct load order
- CodeBlock component supports both code prop and children for flexibility

## [0.1.0] - 2025-11-20

### Added
- Initial Phase 1 implementation with core PostgreSQL support
- Phase 2 schema versioning with retention management
- Phase 3 advanced PostgreSQL features (views, functions, triggers, partitioned tables)
- Phase 4 multi-file schema output with ZIP storage
- Multi-database adapter support (PostgreSQL, MySQL, SQLite)
- Rails Engine with Web UI for browsing schema versions
- Docker development environment with integration apps
- GitHub Pages React documentation site
- Core introspection for PostgreSQL, MySQL, and SQLite metadata
- Table, index, foreign key, and extension generators
- Configuration system with validation and feature toggles
- Rails Railtie integration with rake tasks
- Comprehensive test coverage (unit, integration, comparison tests)
- Clean, deterministic SQL formatting
- Support for schema.rb and structure.sql formats
- Directory-based multi-file dumps with 500 LOC chunking
- Manifest-driven schema loading with dependency ordering
- ZIP archive storage for multi-file schemas in database
- Web UI with Bootstrap 5 for viewing and downloading schemas
- Authentication patterns for securing engine routes
- MySQL stored procedures and triggers support
- SQLite PRAGMA settings and inline foreign keys
- Comprehensive documentation with database-specific guides
