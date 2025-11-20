# Schema Version Hash-Based Deduplication

## Overview

Add MD5 hash-based deduplication to schema version storage to avoid storing duplicate versions when schema content hasn't changed. Only store new versions when schema hash differs from the most recent stored version.

## Problem Statement

Currently, `db:schema:store` creates a new schema version entry every time it runs, even if the schema content hasn't changed. This leads to:

- **Storage bloat**: Duplicate versions consume unnecessary database space
- **Noisy version history**: Hard to identify actual schema changes
- **Inefficient retention management**: Cleanup deletes actual unique versions when duplicates exist
- **Unclear audit trail**: Multiple identical entries obscure schema evolution timeline

## Solution

Add `content_hash` column to `better_structure_sql_schema_versions` table storing MD5 hash of complete schema content:

- **Single-file mode**: Hash entire schema SQL content
- **Multi-file mode**: Hash combined content from all chunked files (same as stored in `content` column)
- **Pre-store validation**: Query for most recent version's hash, compare before INSERT
- **Idempotent storage**: Skip storage if hash matches latest, report "No changes detected"
- **Breaking change acceptable**: No backward compatibility needed (gem not in production use)

## Use Cases

### Developer Workflow
```bash
# Make schema changes and migrate
rails db:migrate  # Automatically dumps schema as part of migration

# Store the dumped schema (reads from filesystem, hashes, stores if new)
rails db:schema:store
# => "Stored schema version #42 (MD5: a3f5c9...)"

# No schema changes, run again
rails db:schema:store  # Reads schema, hashes, skips (hash matches)
# => "No schema changes detected (matches version #42)"

# Make more schema changes
rails db:migrate  # Automatically dumps new schema

# Store again - creates new version (different hash)
rails db:schema:store  # Reads schema, hashes, stores
# => "Stored schema version #43 (MD5: b7e2d1...)"
```

**Note**: `db:migrate` automatically dumps the schema, so `db:schema:store` just reads the existing schema files from filesystem.

### CI/CD Integration
```yaml
# .github/workflows/deploy.yml
- name: Run migrations and store schema
  run: |
    rails db:migrate  # Dumps schema automatically
    rails db:schema:store  # Only stores if hash differs
```

### Automatic Post-Migration Hook
```ruby
# lib/better_structure_sql/migration_patch.rb
# After migrations run:
#   1. Call db:schema:store (dumps, hashes, stores if changed)
#   2. Cleanup multi-file directory after storing ZIP
```

## Configuration

No new configuration needed. Feature automatically enabled when:
- `config.enable_schema_versions = true`
- Migration adding `content_hash` column has run

## Benefits

1. **Storage efficiency**: Eliminate duplicate versions
2. **Clear history**: Only meaningful schema changes tracked
3. **Better retention**: Keep actual unique versions within limit
4. **Fast comparison**: MD5 hash comparison faster than full content comparison
5. **Audit compliance**: Track only actual schema evolution events

## Output Examples

### Version Stored (New Hash)
```
Stored schema version #15
  Format: sql
  Mode: multi_file
  Files: 47
  PostgreSQL: 15.4
  Size: 125.3 KB
  Hash: a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4
  Total versions: 15
```

### Version Skipped (Duplicate Hash)
```
No schema changes detected
  Current schema matches version #15 (hash: a3f5c9d2...)
  No new version stored
  Total versions: 15
```

### Version List with Hashes
```
rake db:schema:versions

ID  | Format | Mode        | Files | PostgreSQL | Hash (first 8) | Created             | Size
----|--------|-------------|-------|------------|----------------|---------------------|-------
15  | sql    | multi_file  | 47    | 15.4       | a3f5c9d2       | 2025-01-18 10:45:22 | 125 KB
14  | sql    | multi_file  | 45    | 15.4       | b7e2d1c4       | 2025-01-17 15:30:10 | 118 KB
13  | sql    | single_file | -     | 15.3       | c9f8a3b2       | 2025-01-15 09:20:05 | 98 KB
```

## Technical Approach

### Hash Calculation

**Single-File Mode**:
```ruby
content_hash = Digest::MD5.hexdigest(content)
```

**Multi-File Mode**:
```ruby
# Hash the combined content (same as stored in `content` column)
# This ensures consistency with what's stored
combined_content = read_multi_file_content(output_path)
content_hash = Digest::MD5.hexdigest(combined_content)
```

### Storage Flow

When you run `rails db:schema:store`:

1. **Read schema content** from filesystem (already dumped by db:migrate or manual dump)
   - Single-file mode: Read `db/structure.sql`
   - Multi-file mode: Read all files from `db/schema/` directory
2. **Calculate MD5 hash** of complete content
3. **Query latest version** for most recent `content_hash`
4. **Compare hashes**:
   - If match: Skip storage, return status message
   - If different (or no previous versions): Proceed with storage
5. **Store version** with hash included (and ZIP archive for multi-file)
6. **Cleanup filesystem** - Delete multi-file directory after ZIP stored (single files remain)
7. **Cleanup old versions** (retention management based on configured limit)

### Database Changes

**Migration**: Add `content_hash` column (VARCHAR 32, indexed)
```ruby
add_column :better_structure_sql_schema_versions, :content_hash, :string, limit: 32, null: false
add_index :better_structure_sql_schema_versions, :content_hash
```

**Model Validation**: Ensure hash present and valid format (32 hex characters)

### SchemaVersions Module Changes

**New method**: `hash_exists?(hash, connection)`
```ruby
# Query for matching hash in most recent N versions (configurable window)
# Returns true if hash found, false otherwise
```

**Updated method**: `store_current(connection)`
```ruby
# Before calling store():
# 1. Calculate content_hash
# 2. Check hash_exists?(content_hash)
# 3. If exists, return early with skip message
# 4. If new, proceed with store(content_hash: content_hash, ...)
```

**Updated method**: `store(content:, format_type:, pg_version:, content_hash:, **options)`
```ruby
# Accept content_hash parameter
# Include in SchemaVersion.create! call
```

## Edge Cases

### Hash Collision
- **Probability**: MD5 collision for different schemas extremely unlikely
- **Impact**: Would skip storage of genuinely different schema
- **Mitigation**: Acceptable risk (1 in 2^128 probability)
- **Alternative**: Use SHA256 if paranoid (minimal performance difference)

### Migration Table Changes
- **Scenario**: Only `schema_migrations` INSERT values differ
- **Result**: Different hash, new version stored
- **Rationale**: Correct behavior - migration state is part of schema
- **Note**: Content includes migration IDs, so hash changes appropriately

### Database Version Upgrade
- **Scenario**: PostgreSQL 15.3 → 15.4, no schema changes
- **Result**: Hash identical (content unchanged), version NOT stored
- **pg_version column**: Would show old version (15.3)
- **Rationale**: Acceptable - hash tracks content changes, not metadata

### Format/Mode Changes
- **Scenario**: Switch from single_file to multi_file
- **Result**: Content identical, hash identical, version NOT stored
- **Impact**: output_mode column shows old mode
- **Mitigation**: Manual store if metadata accuracy critical

### Empty Schema
- **Scenario**: Brand new database, no tables
- **Result**: Hash of empty/minimal schema
- **First store**: Creates version (no previous hash to compare)
- **Subsequent stores**: Skips if still empty

## Performance Considerations

- **Hash calculation**: MD5 very fast (<1ms for typical schemas)
- **Database query**: Single indexed lookup by hash (`WHERE content_hash = ?`)
- **Comparison**: String equality on 32-char hex (negligible)
- **Storage impact**: 32 bytes per version (minimal overhead)
- **Index size**: Small B-tree index on VARCHAR(32)

## Testing Requirements

### Unit Tests
- Hash calculation for single-file content
- Hash calculation for multi-file combined content
- Hash comparison logic (match vs different)
- Skip storage when hash matches
- Proceed storage when hash differs
- Handle no previous versions case

### Integration Tests
- Full workflow: dump → store → verify version created
- Full workflow: dump → store → store again → verify only one version
- Schema change: dump → store → migrate → dump → store → verify two versions
- Multi-file mode: verify combined content hashed correctly
- Single-file mode: verify file content hashed correctly

### Edge Case Tests
- Empty database schema
- Identical schema, different pg_version metadata
- Identical schema, different output_mode
- Only schema_migrations table differs
- Hash collision simulation (inject duplicate hash, verify behavior)

## Migration Path

### Step 1: Add Migration
```ruby
# db/migrate/YYYYMMDDHHMMSS_add_content_hash_to_schema_versions.rb
class AddContentHashToSchemaVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :better_structure_sql_schema_versions, :content_hash, :string, limit: 32
    add_index :better_structure_sql_schema_versions, :content_hash

    # Backfill existing versions (optional)
    reversible do |dir|
      dir.up do
        BetterStructureSql::SchemaVersion.find_each do |version|
          hash = Digest::MD5.hexdigest(version.content)
          version.update_column(:content_hash, hash)
        end
      end
    end

    # Make NOT NULL after backfill
    change_column_null :better_structure_sql_schema_versions, :content_hash, false
  end
end
```

### Step 2: Update Model
```ruby
# lib/better_structure_sql/schema_version.rb
validates :content_hash, presence: true, format: { with: /\A[a-f0-9]{32}\z/ }
```

### Step 3: Update SchemaVersions Module
- Implement hash calculation
- Implement hash_exists? query
- Update store_current to check hash before storing
- Update store to accept and save content_hash

### Step 4: Update Rake Tasks
- Update output messages to show hash and skip reasons
- Update `db:schema:versions` list to show hash column (first 8 chars)

### Step 5: Documentation
- Update README with deduplication feature
- Add examples showing skip behavior
- Document hash column in schema version table structure

## Non-Goals

- **Content comparison**: Don't compare full content strings (inefficient)
- **Partial hashing**: Don't hash sections separately (complexity, unclear semantics)
- **Configurable hash algorithm**: Always use MD5 (good balance of speed and collision resistance)
- **Hash-based retrieval**: Don't query versions by hash (use ID or created_at)
- **Backward compatibility**: Don't support NULL content_hash (breaking change acceptable)

## Success Criteria

1. ✅ `db:schema:store` skips storage when hash matches latest version
2. ✅ `db:schema:store` creates new version when hash differs
3. ✅ Hash calculated identically for single-file and multi-file modes
4. ✅ Migration adds `content_hash` column with index
5. ✅ Model validates hash presence and format
6. ✅ Rake task output shows hash and skip reasons
7. ✅ Test coverage >95% for hash logic
8. ✅ Performance: hash calculation <5ms for schemas up to 500 tables
9. ✅ Documentation updated with examples and behavior
10. ✅ No duplicate versions stored in integration tests

## Related Components

- **SchemaVersion model**: Add content_hash validation
- **SchemaVersions module**: Hash calculation and comparison logic
- **Rake tasks**: Output messages for skip/store decisions
- **FileWriter**: Content reading (existing, no changes)
- **ZipGenerator**: Archive creation (existing, no changes)
- **Migration**: Add content_hash column
- **Tests**: Unit and integration coverage
