# Phase 2: Schema Versioning

Add database-backed schema version storage with retention management.

## Objectives

- Store schema snapshots in database
- Track PostgreSQL version and metadata
- Implement retention policy
- Provide version retrieval API

## Tasks

### 1. Database Schema

**Migration**: `db/migrate/TIMESTAMP_create_schema_versions.rb`

- [ ] Create migration generator
- [ ] Design schema_versions table:
  - `id` (bigserial primary key)
  - `content` (text, NOT NULL) - Full schema SQL/Ruby
  - `pg_version` (varchar, NOT NULL) - PostgreSQL version
  - `format_type` (varchar, NOT NULL) - 'sql' or 'rb'
  - `created_at` (timestamp, NOT NULL)
- [ ] Add index on created_at DESC
- [ ] Add check constraint for format_type IN ('sql', 'rb')
- [ ] Write migration specs

### 2. ActiveRecord Model

**File**: `lib/better_structure_sql/schema_version.rb`

- [ ] Create SchemaVersion model
- [ ] Add validations:
  - `content` presence
  - `pg_version` presence
  - `format_type` inclusion in ['sql', 'rb']
- [ ] Add scopes:
  - `latest` - most recent version
  - `by_format(type)` - filter by sql/rb
  - `recent(limit)` - last N versions
- [ ] Add instance methods:
  - `size` - content byte size
  - `formatted_size` - human readable (KB/MB)
- [ ] Write model specs

### 3. Version Storage

**File**: `lib/better_structure_sql/schema_versions.rb`

- [ ] Implement `store_current` class method:
  - Read current structure.sql or schema.rb
  - Detect PostgreSQL version from connection
  - Determine format type
  - Create version record
  - Trigger cleanup
- [ ] Implement `store(content:, format_type:, pg_version:)`
- [ ] Add error handling for storage failures
- [ ] Write storage specs

### 4. Version Retrieval

**File**: `lib/better_structure_sql/schema_versions.rb`

- [ ] Implement `latest` - get most recent version
- [ ] Implement `all_versions` - ordered by created_at DESC
- [ ] Implement `find(id)` - get specific version
- [ ] Implement `count` - total versions
- [ ] Implement `by_format(type)` - filter by format_type
- [ ] Write retrieval specs

### 5. Retention Management

**File**: `lib/better_structure_sql/schema_versions.rb`

- [ ] Implement `cleanup!` class method:
  - Respect `schema_versions_limit` config
  - Delete oldest versions beyond limit
  - Skip if limit is 0 (unlimited)
  - Return count of deleted versions
- [ ] Auto-cleanup after `store_current`
- [ ] Add manual rake task `db:schema:cleanup`
- [ ] Write cleanup specs with various limits

### 6. Configuration

**File**: `lib/better_structure_sql/configuration.rb`

Add schema versioning config options:

- [ ] `enable_schema_versions` (boolean, default: false)
- [ ] `schema_versions_limit` (integer, default: 10)
- [ ] `schema_versions_table` (string, default: 'better_structure_sql_schema_versions')
- [ ] Validate limit >= 0
- [ ] Write configuration specs

### 7. PostgreSQL Version Detection

**File**: `lib/better_structure_sql/pg_version.rb`

- [ ] Implement version detection from connection
- [ ] Parse version string (e.g., "PostgreSQL 14.5")
- [ ] Extract major.minor version
- [ ] Handle different version formats
- [ ] Cache version during dumper run
- [ ] Write version detection specs

### 8. Rake Tasks

**File**: `lib/tasks/better_structure_sql.rake`

- [ ] `db:schema:store` - Store current schema
- [ ] `db:schema:versions` - List all versions with metadata
- [ ] `db:schema:cleanup` - Manual cleanup
- [ ] Add helpful output messages
- [ ] Write rake task specs

### 9. Installation Generator

**File**: `lib/generators/better_structure_sql/install_generator.rb`

- [ ] Update install generator to:
  - Create initializer
  - Create migration if schema_versions enabled
  - Show post-install instructions
- [ ] Add `--skip-migration` option
- [ ] Write generator specs

### 10. Integration with Dumper

**File**: `lib/better_structure_sql/dumper.rb`

- [ ] Add optional auto-store after dump
- [ ] Add `store_version: true` parameter to dump method
- [ ] Check if schema_versions enabled
- [ ] Write integration specs

### 11. API Helpers (Documentation Only)

**File**: `docs/schema_versions.md`

- [ ] Document example authenticated endpoint
- [ ] Provide controller example code
- [ ] Provide routes example
- [ ] Add curl examples
- [ ] Add download script example
- [ ] Note: Implementation left to users

### 12. Testing

**Specs**: `spec/`

- [ ] Unit tests for SchemaVersion model
- [ ] Unit tests for storage methods
- [ ] Unit tests for cleanup with various limits
- [ ] Integration tests:
  - Store and retrieve versions
  - Cleanup retention policy
  - Multiple format types (sql + rb)
  - Version listing and filtering
- [ ] Test edge cases:
  - No versions stored
  - Limit = 0 (unlimited)
  - Limit = 1 (keep only latest)
  - Large content (>1MB)
  - Concurrent storage
- [ ] Performance tests for cleanup

### 13. Error Handling

- [ ] Handle missing schema_versions table gracefully
- [ ] Handle storage failures (disk full, permissions)
- [ ] Handle invalid format_type
- [ ] Provide helpful error messages
- [ ] Write error handling specs

### 14. Documentation

- [ ] Update README with schema versions feature
- [ ] Complete schema_versions.md documentation
- [ ] Add migration guide
- [ ] Document retention strategies
- [ ] Add troubleshooting section

## Acceptance Criteria

- [ ] Schema versions stored successfully in database
- [ ] Retention policy works correctly
- [ ] Can retrieve versions by ID and filters
- [ ] PostgreSQL version tracked accurately
- [ ] Cleanup respects configured limit
- [ ] Works with both SQL and Ruby schema formats
- [ ] All specs passing
- [ ] Documentation complete with examples

## Files to Create/Modify

```
lib/
  better_structure_sql/
    schema_version.rb (NEW)
    schema_versions.rb (NEW)
    pg_version.rb (NEW)
    configuration.rb (MODIFY)
    dumper.rb (MODIFY)

lib/generators/
  better_structure_sql/
    install_generator.rb (MODIFY)

lib/tasks/
  better_structure_sql.rake (NEW)

db/migrate/
  TIMESTAMP_create_better_structure_sql_schema_versions.rb (GENERATED)

spec/
  better_structure_sql/
    schema_version_spec.rb (NEW)
    schema_versions_spec.rb (NEW)
    pg_version_spec.rb (NEW)
  integration/
    schema_versioning_spec.rb (NEW)
  tasks/
    better_structure_sql_rake_spec.rb (NEW)
```

## Testing Strategy

Test with dummy app:
- Store multiple versions over time
- Test cleanup with limits: 1, 5, 10, 0 (unlimited)
- Test both SQL and Ruby format storage
- Test version retrieval and listing
- Test concurrent storage (multi-threaded)
- Verify PostgreSQL version accuracy
- Test large schema content (500+ tables)

## Database Compatibility

Ensure compatibility with:
- PostgreSQL 12, 13, 14, 15, 16
- Rails 7.0, 7.1, 7.2
- ActiveRecord connection pooling

## Next Phase

After Phase 2 completion, proceed to Phase 3: Advanced Features.
