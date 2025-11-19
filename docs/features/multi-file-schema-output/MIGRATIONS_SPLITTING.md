# Schema Migrations Splitting

## Problem

In long-running Rails applications with thousands of migrations, the schema_migrations INSERT statement in `structure.sql` becomes massive:

```sql
INSERT INTO "schema_migrations" (version) VALUES
('20150101120000'),
('20150102130000'),
('20150103140000'),
... (2,000 more lines) ...
('20251119090000');
```

**Issues:**
- Single INSERT statement with 2,000+ values is hard to read
- Git diffs show entire migration list for one new migration
- Merge conflicts when multiple developers add migrations
- Hard to find specific migration version

## Solution: Split Migrations into Separate Directory

When using multi-file output, schema migrations get their own treatment in a dedicated directory.

### Directory Structure

```
db/schema/
├── _header.sql
├── _manifest.json
├── 1_extensions/
├── ...
├── 9_triggers/
└── migrations/           # New migrations directory
    ├── 000001.sql       # First 500 migrations
    ├── 000002.sql       # Next 500 migrations
    ├── 000003.sql       # Next 500 migrations
    └── 000004.sql       # Remaining migrations
```

### Migration File Format

Each file contains ~500 migration INSERT statements:

**File: `db/schema/migrations/000001.sql`**
```sql
-- Schema Migrations (1-500)
INSERT INTO "schema_migrations" (version) VALUES
('20150101120000'),
('20150102130000'),
('20150103140000'),
... (497 more) ...
('20160615090000');
```

**File: `db/schema/migrations/000002.sql`**
```sql
-- Schema Migrations (501-1000)
INSERT INTO "schema_migrations" (version) VALUES
('20160616100000'),
('20160617110000'),
... (497 more) ...
('20180301150000');
```

### Configuration

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'

  # Migrations splitting
  config.split_migrations = true          # Enable splitting (default: true for multi-file)
  config.migrations_per_file = 500        # Migrations per file (default: 500)
end
```

## Benefits

### 1. Clean Git Diffs

**Before (single file):**
```bash
$ git diff db/structure.sql
# Shows all 2,000 migration lines + one new line
```

**After (split files):**
```bash
$ git diff db/schema/migrations/
# Shows only: migrations/000004.sql (+1 line at end)
```

### 2. Merge Conflict Resolution

**Before:**
```sql
INSERT INTO "schema_migrations" (version) VALUES
...
<<<<<<< HEAD
('20251119090000');
=======
('20251119091500');
>>>>>>> feature-branch
```

**After:**
```bash
# Developer A added: migrations/000004.sql (ends with '20251119090000')
# Developer B added: migrations/000004.sql (ends with '20251119091500')

# Conflict in single file, but easy to resolve:
# Both migrations exist, just merge both lines
```

### 3. Navigation

**Finding migration 20180515120000:**

Before: Search through 2,000-line INSERT statement

After:
```bash
$ grep -r "20180515120000" db/schema/migrations/
db/schema/migrations/000002.sql:('20180515120000'),
```

### 4. Incremental Loading

When loading schema, migrations can be inserted in batches:

```ruby
# Load migrations in chunks for better performance
Dir.glob('db/schema/migrations/*.sql').sort.each do |file|
  connection.execute(File.read(file))
end
```

## Implementation Details

### Dumper Modification

**File**: `lib/better_structure_sql/dumper.rb`

```ruby
def schema_migrations_section
  migrations = fetch_schema_migrations

  if config.split_migrations && output_mode == :multi_file
    # Return array of chunked INSERT statements
    chunk_migrations(migrations, config.migrations_per_file)
  else
    # Return single INSERT statement (current behavior)
    generate_single_migration_insert(migrations)
  end
end

private

def chunk_migrations(migrations, chunk_size)
  migrations.each_slice(chunk_size).map.with_index do |chunk, index|
    start_num = (index * chunk_size) + 1
    end_num = start_num + chunk.size - 1

    <<~SQL
      -- Schema Migrations (#{start_num}-#{end_num})
      INSERT INTO "schema_migrations" (version) VALUES
      #{chunk.map { |v| "('#{v}')" }.join(",\n")};
    SQL
  end
end
```

### FileWriter Integration

**File**: `lib/better_structure_sql/file_writer.rb`

```ruby
def write_multi_file(base_path, sections)
  # ... existing code ...

  # Handle migrations specially
  if sections[:migrations].is_a?(Array)
    # Multiple migration chunks
    migrations_dir = File.join(base_path, 'migrations')
    FileUtils.mkdir_p(migrations_dir)

    sections[:migrations].each_with_index do |chunk, index|
      filename = format_filename(index + 1)
      write_chunk(migrations_dir, filename, chunk)
    end
  end

  # ... rest of code ...
end
```

### Manifest Update

**File**: `_manifest.json`

```json
{
  "version": "1.0",
  "total_files": 247,
  "total_lines": 98543,
  "directories": {
    "1_extensions": {"files": 1, "lines": 12},
    "4_tables": {"files": 156, "lines": 78432},
    "migrations": {"files": 4, "lines": 2143}
  }
}
```

**Note**: Load order is implicit from numbered directories and file names. No need for explicit `load_order` array that could contain thousands of file paths.

## Edge Cases

### 1. Exactly 500 Migrations

```
migrations/000001.sql (500 migrations)
# No 000002.sql needed
```

### 2. Zero Migrations

```
# migrations/ directory not created
# No migration files in output
```

### 3. One Migration

```
migrations/000001.sql (1 migration)
```

### 4. 2,143 Migrations

```
migrations/000001.sql (500 migrations: 1-500)
migrations/000002.sql (500 migrations: 501-1000)
migrations/000003.sql (500 migrations: 1001-1500)
migrations/000004.sql (500 migrations: 1501-2000)
migrations/000005.sql (143 migrations: 2001-2143)
```

## Loading Order

Migrations are loaded **last** in the schema load order:

```
1. _header.sql (SET statements)
2. 1_extensions/ (extensions)
3. 2_types/ (types)
4. 3_sequences/ (sequences)
5. 4_tables/ (tables)
6. 5_indexes/ (indexes)
7. 6_foreign_keys/ (foreign keys)
8. 7_views/ (views)
9. 8_functions/ (functions)
10. 9_triggers/ (triggers)
11. migrations/ (schema_migrations INSERT)  ← Last
```

This ensures the schema_migrations table exists before INSERTs are attempted.

## Testing

### Generate Many Migrations (Test Data)

```ruby
# integration/db/seeds.rb

# Generate 2,000 fake migrations for testing
puts "Generating test migrations..."

2000.times do |i|
  timestamp = (Date.new(2015, 1, 1) + i.days).strftime('%Y%m%d') + sprintf('%06d', i)

  ActiveRecord::Base.connection.execute(
    "INSERT INTO schema_migrations (version) VALUES ('#{timestamp}')"
  )
end

puts "✓ Generated 2,000 test migrations"
```

### Verify Splitting

```bash
# Dump with splitting
rails db:schema:dump_better

# Check migration files
ls db/schema/migrations/
# Output:
# 000001.sql  000002.sql  000003.sql  000004.sql

# Count lines
wc -l db/schema/migrations/*.sql
# Each file should be ~505 lines (500 migrations + header + syntax)
```

### Verify Loading

```bash
# Drop and recreate
rails db:drop db:create

# Load schema
rails db:schema:load_better

# Verify migrations loaded
rails runner "puts SchemaVersion.count"
# Output: 2000
```

## Performance Comparison

### Single File Approach

```sql
-- db/structure.sql (line ~4000-6000)
INSERT INTO "schema_migrations" (version) VALUES
('20150101120000'),
... (2,000 lines) ...
('20251119090000');

-- Issues:
-- - 2,000 line INSERT is slow to parse
-- - Memory spike during execution
-- - Single transaction for all inserts
```

### Multi-File Approach

```sql
-- db/schema/migrations/000001.sql
INSERT INTO "schema_migrations" (version) VALUES
... (500 migrations) ...

-- db/schema/migrations/000002.sql
INSERT INTO "schema_migrations" (version) VALUES
... (500 migrations) ...

-- Benefits:
-- - Smaller INSERT statements (faster parsing)
-- - Can be loaded in parallel (future optimization)
-- - Lower memory per statement
-- - Multiple transactions (better error isolation)
```

### Benchmark Results (Expected)

| Metric | Single INSERT | Split INSERTs |
|--------|---------------|---------------|
| Parse time (2,000 migrations) | ~150ms | ~100ms (4x 25ms) |
| Memory peak | 15MB | 4MB per file |
| Load time | 2.5s | 2.1s (faster) |
| Git diff size (1 new migration) | 2,001 lines | 1 line |

## Configuration Options

```ruby
BetterStructureSql.configure do |config|
  # Multi-file output
  config.output_path = 'db/schema'

  # Migration splitting
  config.split_migrations = true           # Enable (default: true for multi-file)
  config.migrations_per_file = 500         # Chunk size (default: 500)

  # Alternative: Keep migrations in single file
  # config.split_migrations = false        # Single migrations file
end
```

### Rationale for Defaults

**migrations_per_file = 500:**
- Balances file count vs file size
- 2,000 migrations = 4 files (manageable)
- 10,000 migrations = 20 files (still reasonable)
- Each file ~500 lines (easy to navigate)

**split_migrations = true (for multi-file):**
- Consistent with multi-file philosophy
- Git benefits are significant
- Minimal complexity overhead

## Future Enhancements

### Parallel Migration Loading

```ruby
# Load migration files in parallel for faster schema restoration
require 'concurrent-ruby'

pool = Concurrent::FixedThreadPool.new(4)
Dir.glob('db/schema/migrations/*.sql').each do |file|
  pool.post do
    connection = ActiveRecord::Base.connection_pool.checkout
    connection.execute(File.read(file))
    ActiveRecord::Base.connection_pool.checkin(connection)
  end
end
pool.shutdown
pool.wait_for_termination
```

**Benefit**: 3-4x faster loading for large migration sets

### Chronological Organization

Instead of numeric chunks, organize by year:

```
db/schema/migrations/
├── 2015.sql  (all 2015 migrations)
├── 2016.sql  (all 2016 migrations)
├── 2017.sql
...
└── 2025.sql
```

**Benefit**: Easier to find migrations by timeframe

### Metadata in Manifest

```json
{
  "directories": {
    "migrations": {
      "files": 4,
      "total_migrations": 2143,
      "date_range": {
        "earliest": "20150101120000",
        "latest": "20251119090000"
      },
      "chunks": [
        {"file": "000001.sql", "range": "20150101-20160615", "count": 500},
        {"file": "000002.sql", "range": "20160616-20180301", "count": 500},
        {"file": "000003.sql", "range": "20180302-20200708", "count": 500},
        {"file": "000004.sql", "range": "20200709-20251119", "count": 643}
      ]
    }
  }
}
```

## Migration Guide

### Enabling Migration Splitting

**Step 1**: Update configuration
```ruby
config.split_migrations = true
```

**Step 2**: Dump schema
```bash
rails db:schema:dump_better
```

**Step 3**: Verify
```bash
ls db/schema/migrations/
wc -l db/schema/migrations/*.sql
```

**Step 4**: Commit
```bash
git add db/schema/migrations/
git commit -m "Split schema migrations into multiple files"
```

### Disabling Migration Splitting

```ruby
config.split_migrations = false
```

Migrations will be included as single INSERT in the appropriate position.
