# Multi-File Schema Output for Large Databases

## Overview

Enhance BetterStructureSql to handle massive database schemas (tens of thousands of tables, triggers, functions) by splitting schema output into multiple files organized in a directory structure, while maintaining single-blob storage in the database for versioning.

## Motivation: Real-World Example

The integration app includes a large schema generator demonstrating the problem. Run this to see why multi-file output is essential:

```bash
cd integration
rails db:seed  # Generates 50 tables, 150 indexes, 25 FKs, 20 views, 10 functions, 15 triggers
rails db:schema:dump
wc -l db/structure.sql
# Output: 4287 db/structure.sql
```

**The Problem:**
- Opening a 4,000+ line file is slow in most editors
- Finding a specific table requires scrolling or searching
- Git diffs show the entire file for a one-line change
- Merge conflicts are extremely difficult to resolve
- Code reviews become painful

**The Solution (after multi-file implementation):**
```bash
$ find db/schema -type f -name "*.sql" | wc -l
72 files

$ ls db/schema/
1_extensions/  4_tables/      7_views/       _header.sql
2_types/       5_indexes/     8_functions/   _manifest.json
3_sequences/   6_foreign_keys/ 9_triggers/

$ git diff db/schema/  # After adding 1 table
# Shows only: db/schema/4_tables/000011.sql (new file, 48 lines)
```

Each file is ~50-500 lines, easy to navigate, and git diffs are clean and focused.

## Problem Statement

Companies with very large database schemas face challenges with monolithic `structure.sql` files:

- **Massive schemas**: Tens of thousands of tables, triggers, functions, views
- **Single file limitations**:
  - Difficult to navigate and search
  - Slow to load in editors
  - Hard to review in code reviews
  - Poor git diff performance
  - High memory consumption during load
- **Developer experience**: Need to quickly locate specific tables/triggers without scrolling through massive files

## Solution

### Local Multi-File Output

When `config.output_path` has no file extension (e.g., `'db/schema'`), it's treated as a directory and the gem splits output into multiple files organized by object type:

**Detection Rule**:
- No extension → Directory → Multi-file mode (e.g., `'db/schema'`)
- Has extension → File → Single-file mode (e.g., `'db/structure.sql'` or `'db/schema.rb'`)

```
db/schema/
├── 1_extensions/
│   └── 000001.sql
├── 2_types/
│   └── 000001.sql
├── 3_sequences/
│   ├── 000001.sql
│   └── 000002.sql
├── 4_tables/
│   ├── 000001.sql  (500 LOC max per file)
│   ├── 000002.sql
│   └── 000003.sql
├── 5_indexes/
│   ├── 000001.sql
│   └── 000002.sql
├── 6_foreign_keys/
│   └── 000001.sql
├── 7_views/
│   └── 000001.sql
├── 8_functions/
│   ├── 000001.sql
│   └── 000002.sql
├── 9_triggers/
│   └── 000001.sql
├── migrations/       (schema_migrations INSERTs, 500 per file)
│   ├── 000001.sql
│   ├── 000002.sql
│   └── 000003.sql
├── _header.sql       (SET statements, search path)
└── _manifest.json    (metadata about split files)
```

### Chunking Strategy

**500 LOC Soft Limit**:
- When current file + next object would exceed 550 LOC → create new file
- If current file is 450 LOC and next object is 100 LOC (total 550) → overflow, new file

**Single Large Object Handling**:
- If a single object > 500 LOC (e.g., 600-column table, complex trigger) → store in dedicated file
- No artificial splitting of individual objects
- Files can exceed 500 LOC if containing a single large object

**Numbering**:
- Zero-padded sequential: `000001.sql`, `000002.sql`, `000003.sql`
- Up to 999,999 files per directory (6 digits)
- Files numbered in dependency-safe order

### Database Storage (Unchanged)

**SchemaVersions table continues to store as single blob**:
- Combine all split files into one content string
- Store as single `TEXT` field in `better_structure_sql_schema_versions`
- Web UI download provides ZIP file containing reconstructed directory structure
- No changes to database schema or versioning logic

## Use Cases

### UC-1: Developer with Massive Schema

**Scenario**: Company has 15,000 tables, 30,000 triggers, 5,000 functions

**Current Pain**: Single 2MB `structure.sql` file crashes text editors, impossible to navigate

**Solution**:
```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'  # Directory, not file
  config.max_lines_per_file = 500   # Configurable limit
end
```

**Result**:
- Schema split across ~300 files in organized directories
- Each file 200-500 LOC, easily navigable
- Git diffs show only affected files
- Developers can grep within `db/schema/tables/` to find specific tables

### UC-2: Code Review for Schema Changes

**Scenario**: Pull request adds 5 new tables and 10 triggers

**Current Pain**: Reviewer must scroll through 10,000-line file to find changes

**Solution**: Git diff shows only affected files:
```
db/schema/tables/000042.sql    (new file)
db/schema/triggers/000018.sql  (modified)
```

**Benefit**: Reviewer sees exactly what changed, no noise

### UC-3: Schema Version Download

**Scenario**: Developer needs to restore schema from version 2 weeks ago

**Current Flow**: Click "Download" on version → receives `structure.sql`

**New Flow**:
- Click "Download" on version → receives `schema_version_123.zip`
- Extract ZIP → gets full directory structure
- Can `unzip` and explore or load directly

**Web UI**:
- Download button generates ZIP on-the-fly using `rubyzip`
- ZIP contains reconstructed directory structure from single blob
- No need to store ZIPs on disk, generated per-request

## Configuration

### New Options

```ruby
BetterStructureSql.configure do |config|
  # Enable multi-file output by using directory path
  config.output_path = 'db/schema'  # Directory → multi-file
  # config.output_path = 'db/structure.sql'  # File → single file (default)

  # Chunking settings
  config.max_lines_per_file = 500        # Soft limit (default: 500)
  config.overflow_threshold = 1.1        # 10% overflow allowed (default: 1.1)
  # If current + next > 500 * 1.1 (550) → new file

  # Manifest generation
  config.generate_manifest = true        # Create _manifest.json (default: true)

  # Existing options work the same
  config.enable_schema_versions = true
  config.include_functions = true
end
```

### Backward Compatibility

**Default behavior unchanged**:
- `config.output_path = 'db/structure.sql'` (file) → single file output
- `config.output_path = 'db/schema'` (directory) → multi-file output
- Detection: If path has no extension or ends with `/` → directory

## Output Format Details

### Directory Structure

Each object type gets a subdirectory:
- `extensions/` - PostgreSQL extensions
- `types/` - Custom types (enums, composites, domains)
- `sequences/` - Sequence objects
- `tables/` - Table definitions with columns and constraints
- `indexes/` - Index definitions
- `foreign_keys/` - Foreign key constraints
- `views/` - Regular views
- `materialized_views/` - Materialized views
- `functions/` - User-defined functions
- `triggers/` - Trigger definitions
- `_header.sql` - SET statements and search path
- `_manifest.json` - Metadata

### File Naming

**Numbered files**: `000001.sql`, `000002.sql`, etc.
- Sequential numbering within each directory
- Zero-padded to 6 digits (supports up to 999,999 files)
- Ordering matches dependency-safe order from Dumper

**Special files**:
- `_header.sql` - Executed first (SET statements)
- `_manifest.json` - Optional metadata file

### Manifest File Format

`_manifest.json` provides metadata about the split:

```json
{
  "version": "1.0",
  "generated_at": "2025-11-19T10:30:00Z",
  "pg_version": "14.5",
  "format": "sql",
  "total_files": 247,
  "total_lines": 98543,
  "max_lines_per_file": 500,
  "directories": {
    "1_extensions": {"files": 1, "lines": 12},
    "2_types": {"files": 3, "lines": 145},
    "3_sequences": {"files": 8, "lines": 892},
    "4_tables": {"files": 156, "lines": 78432},
    "5_indexes": {"files": 45, "lines": 9821},
    "6_foreign_keys": {"files": 12, "lines": 3421},
    "7_views": {"files": 7, "lines": 2134},
    "8_functions": {"files": 11, "lines": 3012},
    "9_triggers": {"files": 4, "lines": 674},
    "migrations": {"files": 3, "lines": 1520}
  }
}
```

**Note**: Load order is implicit from numbered directory names (1_extensions, 2_types, etc.) and numeric file names (000001.sql, 000002.sql). No need to store explicit load_order array that could become huge with thousands of files.

## Loading Multi-File Schemas

### Rake Task

```bash
rails db:schema:load_better
```

**Behavior**:
- Auto-detects single file vs directory
- If directory: loads files in dependency order using manifest
- If file: loads as single SQL file (current behavior)

**Load Strategy**:
- Load one directory at a time
- Concatenate all files within directory
- Execute directory contents as single SQL statement
- Example: 4_tables/ (150 files) → concatenate all → execute once

**Load Order**:
1. `_header.sql` (SET statements) - execute once
2. `1_extensions/` - concatenate all files, execute once
3. `2_types/` - concatenate all files, execute once
4. `3_sequences/` - concatenate all files, execute once
5. `4_tables/` - concatenate all files, execute once
6. `5_indexes/` - concatenate all files, execute once
7. `6_foreign_keys/` - concatenate all files, execute once
8. `7_views/` - concatenate all files, execute once
9. `8_functions/` - concatenate all files, execute once
10. `9_triggers/` - concatenate all files, execute once
11. `migrations/` - concatenate all files, execute once

**Total SQL Executions**: Maximum 11 (header + 9 directories + migrations)

**Memory Footprint**: Load one directory at a time (~1-2MB per directory), not entire schema

### Manual Loading

Developers can load manually by leveraging numbered directories:

```bash
# Load all files in dependency order (numbered directories ensure correct order)
{
  cat db/schema/_header.sql
  for dir in db/schema/{1..9}_*/; do
    cat "$dir"*.sql 2>/dev/null
  done
  cat db/schema/migrations/*.sql 2>/dev/null
} | psql -d myapp_development

# Or more simply (relies on sort order)
find db/schema -name "*.sql" -not -name "_header.sql" | sort | \
  xargs -I {} sh -c 'cat db/schema/_header.sql; cat {}' | psql -d myapp_development
```

**Note**: The numbered directory prefixes (1_, 2_, 3_...) ensure correct load order without needing to read manifest.

## Web UI Enhancements

### Schema Versions Controller

**Download Action** (`GET /schema_versions/:id/download`):

**Single-file format** (format_type = 'sql' or 'rb', non-split):
- Download as `.sql` or `.rb` file
- Current behavior unchanged

**Multi-file format** (detected via manifest in content):
- Generate ZIP file on-the-fly using `rubyzip`
- ZIP contains reconstructed directory structure
- Filename: `schema_version_<id>_<timestamp>.zip`

**Implementation**:
```ruby
def download
  version = SchemaVersion.find(params[:id])

  if multi_file_format?(version.content)
    send_zip_archive(version)
  else
    send_single_file(version)
  end
end

def send_zip_archive(version)
  zip_data = ZipGenerator.generate(version.content)
  send_data zip_data,
            filename: "schema_version_#{version.id}_#{version.created_at.to_i}.zip",
            type: 'application/zip'
end
```

**ZipGenerator** (new class):
- Parses content to identify file boundaries
- Creates in-memory ZIP using `rubyzip`
- Adds all files to ZIP in correct directory structure
- Streams ZIP to client

### Show View Updates

**Display**:
- Detect multi-file format from content
- Show directory tree visualization instead of raw content
- Provide "Download ZIP" button
- Show manifest metadata (file count, total lines, breakdown by type)

**Example**:
```
Schema Version #123
Format: SQL (Multi-File)
PostgreSQL Version: 14.5
Created: 2025-11-19 10:30:00
Total Files: 247
Total Lines: 98,543

Directory Structure:
├── _header.sql (12 lines)
├── extensions/ (1 file, 12 lines)
├── types/ (3 files, 145 lines)
├── tables/ (156 files, 78,432 lines)
└── ...

[Download ZIP]
```

## Performance Considerations

### Memory Efficiency

**Current approach** (single file):
- Build entire content string in memory
- Can be 1-5 MB for large schemas
- Memory spike during dump

**Multi-file approach**:
- Write files incrementally as generated
- Lower peak memory usage
- Can process schemas of any size

### I/O Performance

**Trade-offs**:
- More file operations (open/close for each chunk)
- But smaller individual writes
- Modern filesystems handle many small files well

**Optimization**:
- Buffer writes within each file
- Only fsync after completing each file
- Parallel file writing possible (future optimization)

### Git Performance

**Benefits**:
- Smaller diffs (only changed files)
- Faster `git status`, `git diff`
- Better merge conflict resolution
- Reduced repository bloat

## Compatibility

### Rails Version Support

- Rails 6.0+: Full support
- Rails 5.2: Full support (ActiveRecord connection API unchanged)
- Rails 5.0-5.1: Compatible (not officially tested)

### PostgreSQL Version Support

- PostgreSQL 10+: Full support
- PostgreSQL 9.6: Compatible (no new features required)

### Gem Dependencies

**New dependency**: `rubyzip` (~> 2.3)
- For generating ZIP downloads in Web UI
- Well-maintained, popular gem (50M+ downloads)
- No system dependencies (pure Ruby)

### Migration Path

**Existing projects** (single file):
1. Update config: `config.output_path = 'db/schema'`
2. Run: `rails db:schema:dump_better`
3. Commit multi-file structure
4. Delete old `db/structure.sql`

**Rollback**:
1. Update config: `config.output_path = 'db/structure.sql'`
2. Run: `rails db:schema:dump_better`
3. Single file restored

**No database migration required** - versioning storage unchanged

## Security Considerations

### Path Traversal Prevention

**Validation**:
- Sanitize all file paths
- Prevent `../` in generated filenames
- Restrict output to configured directory only

### ZIP Bomb Protection

**Limits**:
- Maximum file count in ZIP: 10,000 files
- Maximum uncompressed size: 100 MB
- Reject ZIPs with suspicious compression ratios

### File Permissions

**Output files**:
- Created with mode `0644` (owner write, group/other read)
- Respect system umask
- No executable bits

## Testing Strategy

### Unit Tests

- File chunking logic (500 LOC limit)
- Large object handling (single 600 LOC object)
- Directory structure generation
- Manifest generation and parsing
- ZIP archive creation

### Integration Tests

- Full dump with 10,000 tables split across files
- Load multi-file schema and verify database state
- Round-trip: dump → load → dump, compare outputs
- Web UI download ZIP and extract

### Edge Cases

- Empty database → minimal files
- Single huge table (1000 columns) → single file > 500 LOC
- Mixed small/large objects → correct chunking
- Special characters in object names → safe filenames
- Circular dependencies → correct ordering maintained

### Performance Tests

- 50,000 tables: dump time, memory usage, file count
- 100,000 triggers: chunking performance
- ZIP generation: 500-file archive speed
- Load time: compare single vs multi-file

## Documentation Updates

### README.md

Add "Multi-File Output" section with:
- Configuration example
- Use cases
- Migration guide

### CLAUDE.md

Add keywords:
- multi-file schema, directory output, chunking strategy, 500 LOC limit, overflow threshold, manifest generation, rubyzip, ZIP download, large database support, tens of thousands of tables, file splitting, numbered files, directory structure, load order, dependency-safe chunking

### New Docs

- `docs/features/multi-file-schema-output/` (this document)
- `docs/features/multi-file-schema-output/architecture.md` (technical design)
- `docs/features/multi-file-schema-output/plan/` (implementation phases)

## Future Enhancements

### Phase 2+ Possibilities

**Parallel dumping**:
- Generate multiple object types concurrently
- Requires thread-safe file writing

**Compression**:
- Gzip individual files: `000001.sql.gz`
- Reduces disk usage for large schemas

**Incremental dumps**:
- Track changed objects since last dump
- Only regenerate affected files
- Requires change tracking

**Custom chunking strategies**:
- Group related tables (by prefix, schema, etc.)
- Logical grouping instead of LOC-based

**Smart loading**:
- Parallel file loading for faster schema restoration
- Topological sort with parallelism

**Web UI enhancements**:
- Browse directory structure online
- View individual files without downloading ZIP
- Diff between versions at file level
