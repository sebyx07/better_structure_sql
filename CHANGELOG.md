# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-11-23

### Upgrading

1. **Web UI access (breaking).** Outside development and test the engine now answers `403 Forbidden` until access control is declared. In `config/initializers/better_structure_sql.rb` add one of:
   - `BetterStructureSql::Engine.authentication_handled_by_routes!` when the routes that mount the engine already restrict access (Devise `authenticate`, a `constraints` block);
   - `BetterStructureSql::Engine.authenticate_with { |controller| ... }` returning truthy to allow the request.

   An override of `authenticate_access!` keeps working. A separate `before_action` added through `class_eval` needs one of the two calls as well. See [docs/features/web-ui.md](docs/features/web-ui.md).
2. **Ruby and Rails (breaking).** The minimum versions were raised: see `required_ruby_version` and the `rails` dependency in [`better_structure_sql.gemspec`](better_structure_sql.gemspec).
3. **Dump again and commit the diff.** Output changed format once on every database (see Changed), and multi-file dumps are re-chunked.
4. **MySQL and MariaDB: load through the gem.** Set `config.replace_default_load = true` or use `rails db:schema:load_better`. Rails' own `structure.sql` load pipes the file through the `mysql` client, which needs `DELIMITER` directives the dump does not contain.
5. **`Dumper#dump` with schema versions enabled** now stores a version and raises if it cannot. Migrate the versions table, or call `dump(store_version: false)`.
6. **`db:schema:restore` replaces the schema (breaking).** It purges the database before loading the stored version: every table and all data are dropped, the stored schema versions included. It needs `CONFIRM=1` (`CONFIRM=1 rails db:schema:restore[5]`) and runs Rails' protected-environment check, so production is refused unless `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` is set. Scripts that call the task must pass `CONFIRM=1`, and must not expect existing objects or data to survive.

### Added
- PostgreSQL: partitioned tables (`PARTITION BY`, `PARTITION OF ... FOR VALUES`), identity columns, generated columns, range types, exclusion constraints, procedures, view options, column collations, `OWNED BY` for serial sequences
- PostgreSQL: composite, `MATCH FULL`, `DEFERRABLE` and `NOT VALID` foreign keys; `NOT VALID` check constraints; domains with defaults, `NOT NULL` and every check
- PostgreSQL: views are written in dependency order
- PostgreSQL: table inheritance (`INHERITS`, with only the child's own columns and constraints; parents are written first), `UNLOGGED` tables, table storage parameters (`WITH (fillfactor=70)`), comments on procedures
- MySQL: views are written in dependency order (`information_schema.VIEW_TABLE_USAGE` on MySQL 8.0.13+, the view definition on MariaDB)
- MySQL: the `trilogy` driver (the registry requires the gem matching the connection, `mysql2` or `trilogy`) and MariaDB servers
- MySQL: `CHECK` constraints (with `NOT ENFORCED`), `AUTO_INCREMENT`, `ON UPDATE`, expression defaults, generated columns, column collations, `ENGINE` / `COLLATE` table options
- MySQL: full index definitions: `FULLTEXT`, `SPATIAL`, prefix lengths, `DESC` key parts, functional key parts, `INVISIBLE`
- SQLite: `AUTOINCREMENT`, `WITHOUT ROWID`, `STRICT`, collations, unnamed `CHECK` constraints, table-level `UNIQUE`, composite primary keys, generated columns, partial and expression indexes
- Composite foreign keys on MySQL and SQLite (one entry per key, columns in key order)
- Integration apps: `bss:round_trip` in `integration_mysql/` and `integration_sqlite/` (dump, load into an empty database, dump again, compare dumps and the database's own DDL; `ROUND_TRIP_LAYOUT=multi_file` for the directory layout). CI runs it on MySQL and MariaDB with both drivers and on SQLite: see the `integration-*` jobs in `.github/workflows/ci.yml`
- Web UI: `BetterStructureSql::Engine.authenticate_with` and `BetterStructureSql::Engine.authentication_handled_by_routes!`
- Web UI: the version list is paginated with `?page=`
- Multiple databases: non-primary databases are dumped and loaded by the gem at the Rails path (`db/<name>_structure.sql`); `SCHEMA=` is honoured
- `SchemaVersions.store_current` accepts `config:`
- `SchemaVersions.restore(version, db_config:)` (purge, load, record), `SchemaLoader#load_and_record` (load, then record the environment and `schema_sha1` in `ar_internal_metadata`) and `SchemaLoader.schema_sha1(path)` (checksum of a schema file or directory)
- `db:schema:restore` works on MySQL and SQLite and for `rb` versions
- `llms.txt`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue and pull request templates

### Changed
- **BREAKING**: the web UI fails closed outside development and test (see Upgrading)
- **BREAKING**: the minimum Ruby and Rails versions were raised (see the gemspec)
- **BREAKING**: `db:schema:restore` replaces the schema: it purges the database, loads the stored version, then records the environment and `schema_sha1` in `ar_internal_metadata`. It requires `CONFIRM=1` and runs Rails' protected-environment check (production is refused unless `DISABLE_DATABASE_ENVIRONMENT_CHECK=1`). All data and the stored versions in that database are lost. Previously the task executed the version on top of the existing schema, which could not succeed on PostgreSQL (see Upgrading)
- `db:schema:store` and `SchemaVersions.store_current` never delete the multi-file directory; the `keep_directory:` argument is gone
- MySQL output format: column types and defaults are written as the server reports them (`int unsigned`, `datetime(6)`, `tinyint(1)`), views come from `SHOW CREATE VIEW` and no longer carry the database name
- SQLite output format: tables, indexes and views are the original statements from `sqlite_master`, verbatim; of the PRAGMAs only `application_id`, `auto_vacuum` and `user_version` are written, and only when non-zero
- Foreign key statements quote every identifier
- PostgreSQL output format: identifiers are always double-quoted, Rails timestamps are written as `timestamp(6)`, sequences carry `AS integer` where they are not `bigint`
- Multi-file chunking counts the blank line between objects, so files are split at slightly different points
- Multi-file dumps remove files and directories left by a previous dump, and remove `_manifest.json` when `generate_manifest` is off
- Dump files are written atomically (temporary file, then rename)
- Introspection errors raise instead of producing an empty section with a warning
- `SchemaVersions.store_current` raises `SchemaVersionError` when no dump exists; `db:schema:store` then exits 1
- `ZipGenerator.extract_to_directory` raises `ZipError` on an unsafe path or exceeded limits (counted on inflated bytes) and overwrites existing files
- `search_path` must not be blank
- Web UI: text downloads are `text/plain; charset=utf-8`, every response is `Cache-Control: no-store`, ids must be numeric, the version column is labelled "Database"
- Documentation rewritten against the code; stale planning and status documents removed

### Fixed
- PostgreSQL: enums, composites, ranges and domains are created in dependency order, and a domain whose check calls a function after that function (a composite using a later-named enum or a domain, or a domain check calling a function, no longer fails to load)
- PostgreSQL: a function whose `BEGIN ATOMIC` body uses a sequence is created after the sequence
- PostgreSQL: constraint columns and column comments whose names contain a comma or a dot are no longer split apart
- Dependency sorting is linear in the number of objects and dependencies (20,000 objects took seconds)
- SQLite: a dump containing views loads (views were written as `CREATE OR REPLACE VIEW`, which SQLite rejects)
- SQLite: the `schema_migrations` rows are dumped, so a loaded dump has no pending migrations
- MySQL: a composite foreign key is one statement instead of one per column
- MariaDB: a view whose column alias, table alias or qualifier is named like another view no longer makes that view count as a dependency, which could create the view before a view it reads
- MySQL: triggers sharing a table, timing and event keep their firing order (`ACTION_ORDER`) across a dump and load
- MySQL: loading no longer appends Rails query log tags to routine and trigger bodies
- `Dumper#dump(store_version: true)` now stores a version (deduplicated, with a ZIP in multi-file mode) instead of failing silently
- `rails db:schema:load` with `replace_default_load` records the schema checksum in `ar_internal_metadata`
- `config.active_record.maintain_test_schema = false` is respected
- `maintain_test_schema!` with a schema directory: with `replace_default_dump` or `replace_default_load` on, Rails' own refresh runs unchanged; otherwise the directory at `output_path` is loaded through Rails' `load_schema`, which records the environment and `schema_sha1`, and pending migrations are checked
- `rails db:schema:load` loads a schema directory even with `replace_default_load` off
- `db:schema:load_better` records the environment and `schema_sha1` in `ar_internal_metadata`, so a later `db:drop` no longer raises `NoEnvironmentInSchemaError`
- Web UI: the empty version list names `rails db:schema:store`
- `db:schema:cleanup` no longer calls `exit`
- The web UI displays inline content up to its 1 MB limit

## [0.2.2] - 2025-11-23

### Fixed
- Web UI now properly displays multi-file schema content for files under 1MB
- Optimized schema version show page to avoid loading ZIP archives unnecessarily
- Improved memory efficiency by explicitly selecting only needed columns
- Better error messages distinguishing "too large" from "not available" content

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
