# Phase 1: Adapter Infrastructure Foundation

## Objective

Build adapter abstraction layer and migrate PostgreSQL implementation without breaking existing functionality. Zero breaking changes for current users.

## Deliverables

### 1. Adapter Base Class and Registry
**Files**:
- `lib/better_structure_sql/adapters/base_adapter.rb`
- `lib/better_structure_sql/adapters/registry.rb`

**Tasks**:
- Create abstract BaseAdapter class with interface contract
- Define abstract methods for introspection (fetch_extensions, fetch_types, fetch_tables, etc.)
- Define abstract methods for SQL generation (generate_extension, generate_table, etc.)
- Define capability methods (supports_extensions?, supports_materialized_views?, etc.)
- Implement shared utility methods (version comparison, type normalization)
- Create Registry class with adapter factory pattern
- Implement auto-detection from ActiveRecord connection
- Support manual adapter override from configuration
- Add adapter caching per connection instance

### 2. PostgreSQL Adapter Implementation
**Files**:
- `lib/better_structure_sql/adapters/postgresql_adapter.rb`

**Tasks**:
- Migrate all PostgreSQL-specific queries from introspection modules
- Move query logic from `lib/better_structure_sql/introspection/extensions.rb`
- Move query logic from `lib/better_structure_sql/introspection/types.rb`
- Move query logic from `lib/better_structure_sql/introspection/tables.rb`
- Move query logic from `lib/better_structure_sql/introspection/indexes.rb`
- Move query logic from `lib/better_structure_sql/introspection/foreign_keys.rb`
- Move query logic from `lib/better_structure_sql/introspection/views.rb`
- Move query logic from `lib/better_structure_sql/introspection/functions.rb`
- Move query logic from `lib/better_structure_sql/introspection/sequences.rb`
- Move query logic from `lib/better_structure_sql/introspection/triggers.rb`
- Implement all capability methods (return true for PostgreSQL features)
- Implement database_version detection (parse PostgreSQL version string)
- Preserve existing query logic exactly (no behavior changes)
- Return normalized data structures from fetch methods

### 3. Introspection Modules Refactoring
**Files**:
- `lib/better_structure_sql/introspection/extensions.rb`
- `lib/better_structure_sql/introspection/types.rb`
- `lib/better_structure_sql/introspection/tables.rb`
- `lib/better_structure_sql/introspection/indexes.rb`
- `lib/better_structure_sql/introspection/foreign_keys.rb`
- `lib/better_structure_sql/introspection/views.rb`
- `lib/better_structure_sql/introspection/functions.rb`
- `lib/better_structure_sql/introspection/sequences.rb`
- `lib/better_structure_sql/introspection/triggers.rb`

**Tasks**:
- Replace direct queries with adapter delegation
- Add adapter lookup via Registry
- Cache adapter instance in module
- Maintain existing method signatures (backward compatibility)
- Pass connection to adapter methods
- Handle adapter errors gracefully with fallback to empty arrays

### 4. Dumper Adapter Integration
**Files**:
- `lib/better_structure_sql/dumper.rb`

**Tasks**:
- Initialize adapter in constructor via Registry
- Pass adapter to introspection method calls
- Skip sections if adapter doesn't support feature
- Add capability checks before each dump section (dump_extensions, dump_types, etc.)
- Log warnings for skipped features
- Preserve existing dump ordering
- Maintain output format compatibility

### 5. Configuration Adapter Settings
**Files**:
- `lib/better_structure_sql/configuration.rb`
- `lib/better_structure_sql/adapters/postgresql_config.rb`

**Tasks**:
- Add `adapter` attribute (default: :auto)
- Create PostgresqlConfig class for PostgreSQL-specific settings
- Move existing feature toggles to PostgresqlConfig
- Provide `postgresql` accessor method on Configuration
- Add adapter validation (only :auto, :postgresql allowed in Phase 1)
- Document configuration options
- Provide migration guide for existing configurations

### 6. Version Detection Abstraction
**Files**:
- `lib/better_structure_sql/pg_version.rb` → Rename to `database_version.rb`
- `lib/better_structure_sql/adapters/base_adapter.rb` (add version method)

**Tasks**:
- Abstract version detection to BaseAdapter interface
- Implement PostgreSQL version parsing in adapter
- Update references from PgVersion to DatabaseVersion
- Support version comparison helpers
- Cache version string per session

### 7. Testing Infrastructure
**Files**:
- `spec/adapters/base_adapter_spec.rb`
- `spec/adapters/registry_spec.rb`
- `spec/adapters/postgresql_adapter_spec.rb`

**Tasks**:
- Unit tests for BaseAdapter abstract methods
- Unit tests for Registry adapter detection
- Unit tests for PostgresqlAdapter introspection queries
- Unit tests for PostgresqlAdapter SQL generation
- Unit tests for adapter capability methods
- Integration tests with PostgreSQL database
- Test backward compatibility (existing specs should pass unchanged)
- Mock ActiveRecord connections for unit tests

### 8. Documentation Updates
**Files**:
- `README.md`
- `docs/features/multi-database-adapter-support/README.md`
- `docs/features/multi-database-adapter-support/architecture.md`

**Tasks**:
- Document adapter architecture in feature docs
- Update README with adapter pattern explanation
- Add migration guide for existing users (no changes required)
- Document configuration options for adapter override
- API documentation for BaseAdapter interface
- YARD comments on all adapter classes and methods

## Testing Requirements

### Unit Tests
- BaseAdapter abstract interface raises NotImplementedError
- Registry correctly detects PostgreSQL adapter
- Registry returns cached adapter instance
- PostgresqlAdapter implements all abstract methods
- PostgresqlAdapter capability methods return correct values
- PostgresqlAdapter version detection parses correctly
- Configuration validates adapter values
- Configuration provides PostgresqlConfig accessor

### Integration Tests
- Full schema dump with PostgreSQL adapter produces identical output
- All existing integration tests pass unchanged
- Adapter is correctly initialized in Dumper
- Introspection delegates to adapter successfully
- Feature toggles work with adapter configuration
- Schema versioning works with adapter

### Regression Tests
- All existing RSpec tests pass
- Integration app dumps identical schema before/after
- Performance benchmarks within 5% of baseline
- Multi-file output unchanged
- Single-file output unchanged
- Schema version storage unchanged

### Edge Cases
- Adapter detection with unknown adapter name (should raise error in Phase 1)
- Configuration with invalid adapter value
- Missing adapter method implementation
- Connection failure during adapter initialization

## Success Criteria

- All existing tests pass without modification
- PostgreSQL adapter produces byte-for-byte identical output
- No breaking changes to public API
- Configuration backward compatible
- Performance within 5% of baseline
- Code coverage maintained above 95%
- Zero deprecation warnings
- Documentation complete and accurate
- Adapter pattern ready for MySQL/SQLite implementation

## Dependencies

### External Dependencies
- ActiveRecord (existing)
- pg gem (existing)
- RSpec (existing)
- Integration app with PostgreSQL (existing)

### Internal Dependencies
- Configuration system (existing)
- Introspection modules (refactored)
- Generators (minimal changes in Phase 1)
- FileWriter (no changes)
- SchemaVersions (minimal changes)

## Migration Path

### Step 1: Create Adapter Infrastructure (Non-Breaking)
- Add new adapter classes
- No changes to existing code paths
- New code paths unused initially

### Step 2: Refactor Introspection (Backward Compatible)
- Modules delegate to PostgresqlAdapter
- External interface unchanged
- Internal implementation uses adapter

### Step 3: Update Dumper (Backward Compatible)
- Initialize adapter in constructor
- Feature checks using adapter capabilities
- Output format unchanged

### Step 4: Update Configuration (Backward Compatible)
- Add new adapter setting (default: :auto)
- Existing configurations work unchanged
- New PostgresqlConfig optional

### Step 5: Testing and Validation
- Run full test suite
- Compare schema output before/after
- Performance benchmarking
- Integration testing

### Step 6: Documentation and Release
- Update docs with adapter pattern
- Release notes emphasize no breaking changes
- Migration guide (no action required for users)

## Rollback Strategy

If critical issues discovered:
- Adapter detection can fall back to direct queries
- Configuration can default to legacy behavior
- Feature flag to disable adapter system
- Gradual rollout via configuration

## Performance Targets

- Adapter initialization: < 10ms overhead
- Adapter detection: < 5ms overhead
- Query performance: No degradation (queries identical)
- Memory usage: < 1MB increase for adapter instances
- Full dump: Within 5% of baseline performance

## Keywords

Adapter infrastructure, base adapter abstract class, adapter registry factory, PostgreSQL adapter migration, introspection delegation, backward compatibility, zero breaking changes, adapter detection, ActiveRecord connection, capability detection, feature support methods, version detection abstraction, configuration adapter settings, PostgresqlConfig class, adapter caching, normalized data structures, interface contract, abstract methods, concrete implementation, dependency injection, adapter initialization, registry pattern, factory pattern, database version parsing, feature toggles per adapter, introspection refactoring, dumper adapter integration, unit testing adapters, integration testing backward compatibility, regression testing, performance benchmarking, migration path incremental, rollback strategy, gradual adoption, no API changes, existing tests unchanged, schema output identical, code coverage maintenance, documentation complete, YARD comments, migration guide, deprecation-free
