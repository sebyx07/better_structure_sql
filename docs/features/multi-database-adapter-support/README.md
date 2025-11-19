# Multi-Database Adapter Support

## Overview

Extends BetterStructureSql from PostgreSQL-only to support multiple database systems (MySQL, SQLite) through an adapter-based architecture. Enables clean schema dumps for any database type while maintaining deterministic, version-controlled output.

## Problems Solved

**Current limitations:**
- Hardcoded PostgreSQL system catalog queries (pg_extension, pg_type, pg_proc)
- Direct dependency on `pg` gem in gemspec
- PostgreSQL-specific SQL syntax in generators
- No adapter abstraction layer
- Single integration app for testing (PostgreSQL only)

**Solution benefits:**
- Database-agnostic introspection interface
- Conditional gem dependencies (pg, mysql2, sqlite3)
- Adapter pattern for database-specific implementation
- Multiple integration apps for cross-database testing
- Schema versioning works across all database types

## Supported Databases

### Phase 1: PostgreSQL (Current)
- Full feature support (extensions, types, views, functions, triggers)
- Multi-file schema output
- Schema versioning with ZIP storage
- Existing functionality preserved

### Phase 2: MySQL
- Tables, indexes, foreign keys, constraints
- Views (no materialized views)
- Stored procedures and triggers
- Custom types (ENUM as SET)
- Multi-file schema output
- Schema versioning compatible

### Phase 3: SQLite
- Tables, indexes, foreign keys
- Views (no materialized views)
- Triggers (limited)
- No stored procedures
- No custom types
- Single-file schema output recommended
- Schema versioning compatible

## Architecture Pattern

### Adapter Interface
```ruby
BetterStructureSql::Adapters::BaseAdapter
├── PostgresqlAdapter
├── MysqlAdapter
└── SqliteAdapter
```

Each adapter implements:
- Introspection queries (database-specific)
- SQL generation (dialect-specific syntax)
- Feature detection (version-aware capabilities)
- Type mapping (native types to canonical types)

### Adapter Detection
- Auto-detect from `ActiveRecord::Base.connection.adapter_name`
- Manual override via configuration
- Fail gracefully for unsupported adapters

## Configuration

### Gemspec Dependencies
```ruby
# Conditional database adapters
spec.add_dependency 'rails', '>= 7.0'
spec.add_dependency 'rubyzip', '>= 2.0.0'

# Optional database gems
spec.metadata['optional_dependencies'] = {
  'postgresql' => ['pg >= 1.0'],
  'mysql' => ['mysql2 >= 0.5'],
  'sqlite' => ['sqlite3 >= 1.4']
}
```

**User installation:**
```bash
# PostgreSQL users
gem 'better_structure_sql'
gem 'pg'

# MySQL users
gem 'better_structure_sql'
gem 'mysql2'

# SQLite users
gem 'better_structure_sql'
gem 'sqlite3'
```

### Initializer Configuration
```ruby
BetterStructureSql.configure do |config|
  # Auto-detect adapter (default)
  config.adapter = :auto

  # Or explicit override
  config.adapter = :mysql

  # Database-specific feature toggles
  config.mysql.include_stored_procedures = true
  config.postgresql.include_extensions = true
  config.sqlite.include_triggers = true
end
```

## Feature Compatibility Matrix

| Feature | PostgreSQL | MySQL | SQLite |
|---------|-----------|-------|--------|
| Tables | ✓ | ✓ | ✓ |
| Indexes | ✓ | ✓ | ✓ |
| Foreign Keys | ✓ | ✓ | ✓ |
| Check Constraints | ✓ | ✓ (8.0.16+) | ✓ |
| Unique Constraints | ✓ | ✓ | ✓ |
| Views | ✓ | ✓ | ✓ |
| Materialized Views | ✓ | ✗ | ✗ |
| Extensions | ✓ | ✗ | ✗ |
| Custom Types (ENUM) | ✓ | ✓ (SET) | ✗ |
| Composite Types | ✓ | ✗ (JSON) | ✗ |
| Domains | ✓ | ✗ | ✗ |
| Functions | ✓ (plpgsql) | ✓ (procedures) | ✗ |
| Triggers | ✓ | ✓ | ✓ (limited) |
| Sequences | ✓ | ✗ (AUTO_INCREMENT) | ✗ (AUTOINCREMENT) |
| Partitioning | ✓ | ✓ (8.0+) | ✗ |
| Table Inheritance | ✓ | ✗ | ✗ |
| Array Types | ✓ | ✗ (JSON) | ✗ |
| JSON/JSONB | ✓ | ✓ (JSON) | ✓ (JSON) |
| Multi-file Output | ✓ | ✓ | ✓ |
| Schema Versioning | ✓ | ✓ | ✓ |

## Integration Testing Strategy

### Multiple Integration Apps
```
integration/
├── integration_postgresql/  # Existing
├── integration_mysql/       # New
└── integration_sqlite/      # New
```

Each app:
- Database-specific Docker setup
- Adapter-compatible migrations
- Shared test suite
- CI matrix testing

### Docker Compose Strategy
```yaml
# docker-compose.yml supports multiple databases
services:
  postgres:
    image: postgres:15-alpine
  mysql:
    image: mysql:8.0-alpine
  sqlite:
    # No service needed (file-based)
```

### CI Testing Matrix
- PostgreSQL: 13, 14, 15, 16
- MySQL: 8.0, 8.4
- SQLite: 3.40+
- Rails: 7.0, 7.1, 8.0+
- Ruby: 2.7, 3.0, 3.1, 3.2, 3.3

## Migration Path for Existing Users

### PostgreSQL Users (No Changes Required)
```ruby
# Existing setup continues to work
gem 'pg'
gem 'better_structure_sql'

# No configuration changes needed
BetterStructureSql.configure do |config|
  # Same configuration
end
```

### MySQL Users (New)
```ruby
# Install MySQL adapter
gem 'mysql2'
gem 'better_structure_sql'

# Optional configuration
BetterStructureSql.configure do |config|
  config.adapter = :mysql # Auto-detected
  config.mysql.include_stored_procedures = true
end
```

### SQLite Users (New)
```ruby
# Install SQLite adapter
gem 'sqlite3'
gem 'better_structure_sql'

# Optional configuration
BetterStructureSql.configure do |config|
  config.adapter = :sqlite # Auto-detected
  # Limited features auto-disabled
end
```

## Use Cases

### Multi-Database Rails Apps
- Primary database: PostgreSQL
- Analytics database: MySQL
- Test database: SQLite
- Each dumps to separate schema files

### Database Migration Projects
- Migrate from MySQL to PostgreSQL
- Compare schemas side-by-side
- Track schema evolution during migration
- Version both database formats

### Cross-Database Testing
- Test application against multiple databases
- CI matrix with all database types
- Schema compatibility validation
- Performance comparison

### Schema Documentation
- Generate clean SQL for all databases
- Database-agnostic documentation
- Cross-platform schema sharing
- API schema evolution tracking

## Performance Considerations

### Query Optimization
- Adapter-specific query optimization
- Batch queries where possible
- Database-specific indexes on system catalogs
- Cache introspection results per dump session

### Memory Management
- Stream large result sets
- Multi-file chunking for massive schemas
- Database-specific memory limits
- Efficient ZIP archive generation

### Benchmark Targets
- PostgreSQL: Maintain current performance
- MySQL: 100 tables < 10 seconds
- SQLite: 100 tables < 5 seconds (file-based)

## Error Handling

### Unsupported Features
```ruby
# Graceful degradation
if adapter.supports?(:materialized_views)
  dump_materialized_views
else
  log_warning "Materialized views not supported on #{adapter.name}"
end
```

### Version Detection
```ruby
# Database version checks
if adapter.version >= '8.0.16'
  include_check_constraints
else
  warn "Check constraints require #{adapter.name} 8.0.16+"
end
```

### Adapter Detection Failure
```ruby
# Clear error messages
raise AdapterNotSupportedError,
  "Adapter '#{adapter_name}' not supported. " \
  "Supported: postgresql, mysql, sqlite"
```

## Documentation Requirements

### User Documentation
- Installation per database type
- Configuration examples
- Feature compatibility matrix
- Migration guide from PostgreSQL-only
- Troubleshooting per database

### Developer Documentation
- Adapter interface specification
- Adding new database adapters
- Database-specific query patterns
- Testing strategy per adapter
- Performance benchmarks

## Success Criteria

- Zero breaking changes for PostgreSQL users
- Clean adapter abstraction (Single Responsibility)
- MySQL support with 80%+ feature parity
- SQLite support with 60%+ feature parity
- Integration apps for all databases
- CI testing across database matrix
- Documentation for all adapters
- Performance within 20% of pg_dump equivalent
- Gemspec with conditional dependencies
- Schema versioning compatible across databases

## Keywords

Multi-database support, database adapters, adapter pattern, PostgreSQL adapter, MySQL adapter, SQLite adapter, mysql2 gem, sqlite3 gem, conditional dependencies, gemspec optional dependencies, adapter detection, ActiveRecord connection adapter, database introspection abstraction, information_schema portability, system catalog queries, database-specific SQL dialects, feature compatibility matrix, graceful degradation, version detection, MySQL stored procedures, SQLite triggers, MySQL SET type, database type mapping, canonical types, integration testing, multiple integration apps, integration_mysql, integration_sqlite, Docker multi-database, docker-compose multi-service, CI matrix testing, cross-database testing, database migration projects, schema compatibility validation, adapter interface specification, database-agnostic introspection, dialect-specific SQL generation, query optimization per database, adapter-specific indexes, feature detection, version-aware capabilities, backward compatibility, zero breaking changes, PostgreSQL feature parity, MySQL feature parity, SQLite limitations, materialized view support, stored procedure support, trigger support, partitioning support, custom type support, ENUM vs SET, composite types vs JSON, array types alternatives, sequence vs AUTO_INCREMENT, database version requirements, minimum version support, error handling patterns, unsupported feature warnings, adapter not supported errors, configuration per adapter, feature toggles per database, auto-detect adapter, manual adapter override, migration path existing users, multi-database Rails apps, analytics database, test database switching, schema comparison tools, cross-platform schema documentation
