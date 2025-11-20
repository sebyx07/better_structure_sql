# Architecture: Schema Version Hash Deduplication

## Component Overview

Hash-based deduplication adds minimal complexity to existing schema versioning infrastructure. Core change: calculate MD5 hash of schema content before storage, compare with latest version's hash, skip if identical.

## Components and Responsibilities

### 1. SchemaVersion Model
**File**: `lib/better_structure_sql/schema_version.rb`

**New Attributes**:
- `content_hash` (String, 32 chars) - MD5 hexdigest of complete schema content

**New Validations**:
- `validates :content_hash, presence: true`
- `validates :content_hash, format: { with: /\A[a-f0-9]{32}\z/ }`

**Updated Methods**:
- `before_save :calculate_content_hash` - Auto-calculate hash if missing (defensive, should always be provided)

**New Methods**:
- `hash_matches?(other_hash)` - Compare two hashes (simple string equality)

**Unchanged**:
- All existing metadata (`format_type`, `output_mode`, `pg_version`, `content_size`, `line_count`, `file_count`)
- ZIP archive handling
- Scopes and queries

---

### 2. SchemaVersions Module
**File**: `lib/better_structure_sql/schema_versions.rb`

**New Methods**:

`calculate_hash(content)` - Hash calculation
```ruby
# Class method, stateless
# Input: String (schema content)
# Output: String (32-char MD5 hexdigest)
Digest::MD5.hexdigest(content)
```

`latest_hash(connection)` - Retrieve most recent version's hash
```ruby
# Query: SchemaVersion.latest.pluck(:content_hash).first
# Returns: String (hash) or nil (no versions exist)
# Uses existing SchemaVersion.latest scope (ORDER BY created_at DESC LIMIT 1)
```

`hash_exists?(hash, connection)` - Check if hash already stored
```ruby
# Query: SchemaVersion.where(content_hash: hash).exists?
# Alternative: Compare with latest_hash (simpler, sufficient)
# Returns: Boolean
```

**Updated Methods**:

`store_current(connection)` - Pre-storage hash comparison
```ruby
def self.store_current(connection)
  # 1. Detect format, mode, read content (existing logic)
  # 2. Calculate hash: content_hash = calculate_hash(content)
  # 3. Get latest hash: previous_hash = latest_hash(connection)
  # 4. Compare: return skip_message if content_hash == previous_hash
  # 5. Otherwise: store(content_hash: content_hash, ...)
  # 6. Cleanup (existing logic)
end
```

`store(content:, format_type:, pg_version:, content_hash:, **options)` - Accept hash parameter
```ruby
def self.store(content:, format_type:, pg_version:, content_hash:, **options)
  # Add content_hash to SchemaVersion.create! attributes
  # Everything else unchanged
end
```

**Unchanged Methods**:
- `cleanup!` - Retention management
- `latest`, `all_versions`, `find`, `count`, `by_format` - Query methods
- `read_schema_content` - Content reading
- `detect_output_mode`, `deduce_format_type` - Mode/format detection

---

### 3. Database Schema
**Migration**: `db/migrate/YYYYMMDDHHMMSS_add_content_hash_to_schema_versions.rb`

**Changes**:
```sql
ALTER TABLE better_structure_sql_schema_versions
  ADD COLUMN content_hash VARCHAR(32) NOT NULL;

CREATE INDEX index_schema_versions_on_content_hash
  ON better_structure_sql_schema_versions (content_hash);
```

**Backfill** (optional, for existing records):
```ruby
# Calculate hash for each existing version
BetterStructureSql::SchemaVersion.find_each do |version|
  hash = Digest::MD5.hexdigest(version.content)
  version.update_column(:content_hash, hash)
end
```

**Adapters**:
- PostgreSQL: Standard VARCHAR(32), btree index
- MySQL: VARCHAR(32), standard index
- SQLite: TEXT (no length limit), index created

**Index Rationale**:
- Enables fast `WHERE content_hash = ?` lookups
- Small cardinality (one hash per unique schema)
- Typical usage: lookup latest version's hash
- Alternative: No index needed if only comparing with latest (single row scan)

---

### 4. Rake Tasks
**File**: `lib/tasks/better_structure_sql.rake`

**Updated Tasks**:

`db:schema:store` - Enhanced output
```ruby
task :store => :environment do
  result = SchemaVersions.store_current(connection)

  if result.skipped?
    puts "No schema changes detected"
    puts "  Current schema matches version ##{result.version_id} (hash: #{result.hash[0..7]}...)"
    puts "  No new version stored"
    puts "  Total versions: #{result.total_count}"
  else
    puts "Stored schema version ##{result.version.id}"
    puts "  Format: #{result.version.format_type}"
    puts "  Mode: #{result.version.output_mode}"
    puts "  Files: #{result.version.file_count || '-'}"
    puts "  PostgreSQL: #{result.version.pg_version}"
    puts "  Size: #{result.version.formatted_size}"
    puts "  Hash: #{result.version.content_hash}"
    puts "  Total versions: #{result.total_count}"
  end
end
```

`db:schema:versions` - Show hash column
```ruby
# Add content_hash column to output table
# Display first 8 characters: hash[0..7]
# Full width table format with Hash column
```

**Result Object Pattern**:
```ruby
class StoreResult
  attr_reader :version, :skipped, :version_id, :hash, :total_count

  def skipped?
    @skipped
  end
end

# SchemaVersions.store_current returns StoreResult
# Allows rich output without coupling module to I/O
```

---

### 5. Content Reading (Unchanged)
**File**: `lib/better_structure_sql/schema_versions.rb`

Hash calculated on **combined content** for both modes:

**Single-File**:
```ruby
content = File.read(output_path)
content_hash = Digest::MD5.hexdigest(content)
```

**Multi-File**:
```ruby
# Read all files and combine (existing logic)
combined_content = read_multi_file_content(output_path)

# Hash the combined content (NOT individual files)
content_hash = Digest::MD5.hexdigest(combined_content)
```

**Rationale**: Hash must match stored `content` column, which contains combined content for multi-file mode.

---

## Component Interactions

### Storage Flow with Deduplication

```
Rake Task: db:schema:store
  ↓
  (Schema already dumped by db:migrate or manual dump)
  ↓
SchemaVersions.store_current(connection)
  ↓
  ├─→ Detect mode and format
  ├─→ Read content from filesystem
  │   ├─ Single-file: File.read(path)
  │   └─ Multi-file: read_multi_file_content(path)
  ↓
  ├─→ Calculate hash: calculate_hash(content)
  ├─→ Get latest hash: latest_hash(connection)
  ↓
  ├─→ Compare hashes
  │   ├─ Match? → Return StoreResult.skipped (no cleanup needed)
  │   └─ Different? → Proceed ↓
  ↓
  ├─→ Create ZIP (multi-file only)
  ├─→ Count files (multi-file only)
  ↓
SchemaVersions.store(content:, content_hash:, ...)
  ↓
SchemaVersion.create!(
    content: content,
    content_hash: content_hash,
    format_type: format_type,
    pg_version: pg_version,
    output_mode: output_mode,
    zip_archive: zip_archive,
    file_count: file_count
  )
  ↓ (before_save callback)
  ├─→ calculate_content_size
  ├─→ calculate_line_count
  ↓
  ├─→ **NEW: Cleanup filesystem directory (multi-file only)**
  │   └─→ FileUtils.rm_rf(output_path) after ZIP stored
  ↓
SchemaVersions.cleanup!(connection)  # Retention cleanup
  ↓
Return StoreResult.stored
  ↓
Rake Task: Display output
```

### Query Pattern

**Latest Hash Lookup**:
```sql
SELECT content_hash
FROM better_structure_sql_schema_versions
ORDER BY created_at DESC
LIMIT 1;
```

**Index Usage**:
- Uses existing `created_at DESC` index for latest version
- New `content_hash` index unused in typical flow (only one row retrieved)
- Index useful if implementing "find all versions with same hash" (future feature)

---

## Data Flow

### Input: Schema Files
- **Single-file**: `db/structure.sql` (one file)
- **Multi-file**: `db/schema/` directory (47 files across 10 directories)

### Processing: Hash Calculation
```ruby
# Single-file
content = File.read('db/structure.sql')
hash = Digest::MD5.hexdigest(content)
# => "a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4"

# Multi-file (combined)
content = [
  File.read('db/schema/_header.sql'),
  "-- Manifest: ...",  # embedded as comment
  Dir['db/schema/**/*.sql'].sort.map { |f| File.read(f) }.join("\n")
].join("\n")
hash = Digest::MD5.hexdigest(content)
# => "a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4"
```

### Storage: Database Record
```ruby
{
  id: 15,
  content: "SET statement_timeout...\nCREATE EXTENSION...\n...",  # Full combined SQL
  content_hash: "a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4",
  format_type: "sql",
  output_mode: "multi_file",
  pg_version: "15.4",
  content_size: 128354,  # bytes
  line_count: 3421,
  file_count: 47,
  zip_archive: <binary ZIP data>,
  created_at: "2025-01-18 10:45:22"
}
```

### Output: Skip Decision
```ruby
# Get latest hash
latest = SchemaVersion.latest
previous_hash = latest&.content_hash  # "a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4"

# Compare
current_hash = calculate_hash(content)  # "a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4"

if current_hash == previous_hash
  # SKIP - no storage
  StoreResult.new(skipped: true, version_id: latest.id, hash: current_hash)
else
  # STORE - create new version
  version = SchemaVersion.create!(...)
  StoreResult.new(skipped: false, version: version)
end
```

---

## Dependencies

### Existing Components (No Changes Required)
- **FileWriter**: Multi-file chunking and writing
- **ZipGenerator**: Archive creation and extraction
- **SchemaLoader**: Loading schemas from storage
- **Dumper**: Schema generation and orchestration
- **ManifestGenerator**: Manifest JSON generation
- **Configuration**: Settings management

### New Dependencies
- **Digest::MD5**: Ruby standard library (already available)

### Database Dependencies
- **Migration**: Add `content_hash` column before using feature
- **Index**: Optional but recommended for performance

---

## Extension Points

### Future Enhancements

**Hash Algorithm Configuration**:
```ruby
# config/initializers/better_structure_sql.rb
config.hash_algorithm = :md5  # :md5, :sha256, :sha1
```

**Hash Window Comparison**:
```ruby
# Compare against last N versions instead of just latest
# Prevents re-storing after cleanup removes matching version
config.hash_comparison_window = 10  # Check last 10 versions
```

**Hash-Based Queries**:
```ruby
# Find all versions with identical schema
SchemaVersion.where(content_hash: "a3f5c9d2...")

# Group versions by unique schemas
SchemaVersion.group(:content_hash).count
```

**Automatic Deduplication**:
```ruby
# Remove duplicate versions with same hash, keep oldest
SchemaVersions.deduplicate!
```

---

## Testing Strategy

### Unit Tests
**File**: `spec/lib/better_structure_sql/schema_versions_spec.rb`

Tests:
- `calculate_hash(content)` returns 32-char MD5 hexdigest
- `latest_hash(connection)` queries correct version
- `store_current` skips when hash matches
- `store_current` stores when hash differs
- `store_current` stores when no previous versions
- `store` saves content_hash to database

### Integration Tests
**File**: `spec/integration/schema_versioning_spec.rb`

Tests:
- Full flow: dump → store → verify version created with hash
- Duplicate detection: dump → store → store → verify only one version
- Change detection: dump → store → migrate → dump → store → verify two versions
- Multi-file mode: verify combined content hashed correctly
- Single-file mode: verify file content hashed identically

### Model Tests
**File**: `spec/models/schema_version_spec.rb`

Tests:
- `content_hash` validates presence
- `content_hash` validates format (32 hex chars)
- `hash_matches?(other)` compares correctly

---

## Performance Characteristics

### Hash Calculation
- **Algorithm**: MD5 (fast, good collision resistance)
- **Time complexity**: O(n) where n = content length
- **Typical schemas**:
  - 100 tables, 50KB content: <1ms
  - 500 tables, 500KB content: ~5ms
  - 5000 tables, 5MB content: ~50ms
- **Bottleneck**: Disk I/O (reading files), not hash calculation

### Database Queries
- **Latest hash lookup**: 1 query, indexed on `created_at DESC`
- **Index size**: ~32 bytes × number of versions (tiny)
- **Comparison**: String equality (negligible CPU time)

### Storage Decision
- **Skip path**: 1 read query + hash calculation = <10ms overhead
- **Store path**: Same as current (hash calculation negligible)

### Optimization: Cache Latest Hash
```ruby
# Optional: Cache latest hash in memory within store_current call
# Avoids second query if storing multiple databases in loop
@latest_hash ||= latest_hash(connection)
```

---

## Security Considerations

### Hash Collision Risk
- **MD5 collisions**: Theoretically possible, extremely unlikely for natural data
- **Impact**: Would skip storing genuinely different schema
- **Mitigation**: Acceptable risk (probability ~1 in 2^128)
- **Alternative**: Use SHA256 if paranoid (minimal performance difference)

### Timing Attacks
- **Hash comparison**: Use constant-time comparison to prevent timing attacks
- **Ruby**: String equality (`==`) not constant-time
- **Mitigation**: Not a concern (hashes are not secrets, no security boundary)

### Injection Attacks
- **Content hashing**: No SQL injection risk (content never executed)
- **Hash storage**: Parameterized queries (no injection risk)

---

## Rollback Strategy

### If Feature Causes Issues

**Step 1**: Disable hash comparison
```ruby
# Temporary monkey patch in initializer
module BetterStructureSql
  module SchemaVersions
    def self.latest_hash(connection)
      nil  # Always returns nil, disables deduplication
    end
  end
end
```

**Step 2**: Remove column (if necessary)
```ruby
# Migration
remove_column :better_structure_sql_schema_versions, :content_hash
```

**Step 3**: Revert code changes
```bash
git revert <hash-feature-commit>
```

---

## Migration Compatibility

### PostgreSQL, MySQL, SQLite Support

All three adapters support:
- `VARCHAR(32)` or `TEXT` column types
- B-tree indexes on string columns
- `NULL`/`NOT NULL` constraints

**PostgreSQL**:
```sql
ALTER TABLE better_structure_sql_schema_versions
  ADD COLUMN content_hash VARCHAR(32) NOT NULL;
CREATE INDEX index_schema_versions_on_content_hash
  ON better_structure_sql_schema_versions (content_hash);
```

**MySQL**:
```sql
ALTER TABLE better_structure_sql_schema_versions
  ADD COLUMN content_hash VARCHAR(32) NOT NULL;
CREATE INDEX index_schema_versions_on_content_hash
  ON better_structure_sql_schema_versions (content_hash);
```

**SQLite**:
```sql
ALTER TABLE better_structure_sql_schema_versions
  ADD COLUMN content_hash TEXT NOT NULL DEFAULT '';
CREATE INDEX index_schema_versions_on_content_hash
  ON better_structure_sql_schema_versions (content_hash);
```

**Backfill Strategy**:
Same for all adapters - iterate existing records, calculate hash from `content` column, update.

---

## Summary

Hash-based deduplication adds **one column**, **one index**, and **minimal logic** to existing infrastructure:

- **Column**: `content_hash VARCHAR(32) NOT NULL`
- **Index**: B-tree on `content_hash`
- **Logic**: Calculate hash → compare with latest → skip if match
- **Result**: No duplicate versions, clear schema history, efficient storage

Zero impact on existing features. Transparent to users. Automatic deduplication without configuration.
