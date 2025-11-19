# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Fixed

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
