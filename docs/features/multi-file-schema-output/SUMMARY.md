# Multi-File Schema Output - Feature Summary

## Overview

Complete documentation for implementing multi-file schema output in BetterStructureSql gem. Handles massive database schemas (50,000+ tables) by splitting output across organized, numbered directories.

## Documentation Files

### Core Documentation
1. **README.md** - Feature overview, use cases, configuration, examples
2. **architecture.md** - Technical design, components, data flow
3. **GENERATOR.md** - Test data generator for demonstration
4. **MIGRATIONS_SPLITTING.md** - Schema migrations chunking strategy
5. **SUMMARY.md** - This file

### Implementation Plans
1. **plan/phase-1.md** - Core infrastructure (FileWriter, ManifestGenerator, chunking)
2. **plan/phase-2.md** - Schema loading (SchemaLoader) and ZIP storage
3. **plan/phase-3.md** - Web UI integration and downloads
4. **plan/phase-4.md** - Documentation, testing, polish

## Key Design Decisions

### 1. Numbered Directories (Load Order)

**Decision**: Use numbered prefixes (1_, 2_, 3_...) instead of explicit load_order array in manifest

**Rationale**:
- Implicit load order from directory names
- No need to parse manifest for loading
- Manifest stays small even with 10,000+ files
- Simple glob patterns: `Dir.glob('{1..9}_*').sort`

**Structure**:
```
db/schema/
├── 1_extensions/
├── 2_types/
├── 3_sequences/
├── 4_tables/
├── 5_indexes/
├── 6_foreign_keys/
├── 7_views/
├── 8_functions/
├── 9_triggers/
└── migrations/
```

### 2. Manifest Purpose

**Decision**: Manifest provides metadata only, NOT load order

**Contents**:
- Version, timestamp, PostgreSQL version
- Total files, total lines
- Per-directory statistics (file count, line count)

**What it does NOT contain**:
- ❌ load_order array (would be huge with thousands of files)
- ❌ Individual file listings
- ❌ File-level metadata

**Use cases**:
- Web UI displays statistics
- Debugging and diagnostics
- Tooling integration

### 3. Chunking Strategy

**Decision**: 500 LOC soft limit with 10% overflow threshold

**Algorithm**:
- Accumulate objects until reaching ~500 lines
- If next object would exceed 550 lines (10% overflow) → new file
- Single large object (600+ LOC) → dedicated file (OK to exceed limit)

**Benefits**:
- Predictable file sizes
- Balance between file count and file size
- Handles edge cases (huge tables with 600 columns)

### 4. ZIP Storage

**Decision**: Store entire db/schema/ directory as ZIP in database

**Implementation**:
- New column: `zip_archive` (binary, nullable)
- New column: `output_mode` ('single_file' | 'multi_file')
- New column: `file_count` (integer, nullable)

**Storage**:
- Single-file dumps: content only, zip_archive = NULL
- Multi-file dumps: combined content + ZIP archive

**Download**:
- Web UI provides ZIP download
- Developer extracts and replaces local db/schema/

### 5. Migration Splitting

**Decision**: Split schema_migrations INSERTs into 500-migration chunks

**Directory**: `migrations/` (loaded last, after all schema objects)

**Benefits**:
- Clean git diffs (one new migration = one line change in one file)
- Easy merge conflict resolution
- Better performance (smaller INSERT statements)

**Structure**:
```
migrations/
├── 000001.sql  (migrations 1-500)
├── 000002.sql  (migrations 501-1000)
├── 000003.sql  (migrations 1001-1500)
└── 000004.sql  (migrations 1501-2143)
```

## Component Architecture

### New Classes

**FileWriter** - Multi-file output management
- Detect output mode (file vs directory)
- Chunk sections into 500 LOC files
- Create numbered directories
- Write files incrementally

**ManifestGenerator** - Metadata generation
- Calculate statistics (files, lines, breakdown)
- Generate manifest JSON
- Parse existing manifests

**SchemaLoader** - Multi-format schema loading
- Auto-detect file vs directory
- Load numbered directories in order
- No manifest dependency for loading

**ZipGenerator** - ZIP archive operations
- Create ZIP from directory (using rubyzip)
- Extract ZIP to directory
- Validate ZIP safety (file count, size limits)

### Modified Classes

**Dumper** - Orchestration updates
- Detect output mode from config.output_path
- Delegate to FileWriter for writing
- Combine sections for database storage

**Configuration** - New options
- `max_lines_per_file` (default: 500)
- `overflow_threshold` (default: 1.1)
- `generate_manifest` (default: true)
- `split_migrations` (default: true for multi-file)
- `migrations_per_file` (default: 500)

**SchemaVersion Model** - New columns
- `zip_archive` (binary)
- `output_mode` (string)
- `file_count` (integer)

**SchemaVersionsController** - Download action
- Detect multi-file vs single-file
- Send ZIP for multi-file versions
- Send text file for single-file versions

## Implementation Flow

### Dump Flow

```
1. User runs: rails db:schema:dump_better
2. Dumper detects output_mode from config.output_path
3. If directory mode:
   - Generate all sections (existing logic)
   - FileWriter.write_multi_file:
     - Create numbered directories
     - Chunk each section into 500 LOC files
     - Write files with numbered names
   - ManifestGenerator.generate:
     - Calculate statistics
     - Write _manifest.json
   - If versioning enabled:
     - Combine all sections into single content
     - ZipGenerator.create_from_directory
     - Store content + ZIP in database
```

### Load Flow

```
1. User runs: rails db:schema:load_better
2. SchemaLoader detects directory vs file
3. If directory:
   - Load _header.sql → execute once
   - For each numbered directory (1_extensions, 2_types, ...):
     - Concatenate all .sql files in directory
     - Execute concatenated SQL as single statement
   - Load migrations/ directory:
     - Concatenate all .sql files
     - Execute concatenated SQL as single statement
4. Total SQL executions: 11 max (header + 9 dirs + migrations)
5. Memory: ~1-2MB per directory (loaded one at a time)
```

**Key Insight**: One directory = One SQL execution. All files within a directory are concatenated before execution, minimizing database round-trips while keeping memory footprint low.

### Download Flow (Web UI)

```
1. User clicks "Download" on version
2. Controller checks version.output_mode
3. If 'multi_file':
   - Send version.zip_archive as attachment
   - Filename: schema_version_123_1637123456.zip
4. If 'single_file':
   - Send version.content as text file
   - Filename: structure.sql
```

## Configuration Examples

**Detection Rule**: No file extension → directory → multi-file mode

### Single-File (Default)

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/structure.sql'  # .sql extension → single-file
  # or
  config.output_path = 'db/schema.rb'      # .rb extension → single-file
end
```

### Multi-File (Large Schemas)

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'  # No extension → directory → multi-file
  config.max_lines_per_file = 500
  config.overflow_threshold = 1.1
  config.generate_manifest = true
  config.split_migrations = true
  config.migrations_per_file = 500
  config.enable_schema_versions = true
end
```

## Testing Strategy

### Prerequisites
1. Generate large test schema (integration/db/seeds.rb)
   - 50 tables, 150 indexes, 25 FKs, 20 views, 10 functions, 15 triggers
   - Creates ~4,000 line structure.sql

### Unit Tests
- FileWriter chunking algorithm
- ManifestGenerator JSON generation
- SchemaLoader directory parsing
- ZipGenerator archive creation

### Integration Tests
- Full dump cycle (single → multi)
- Round-trip integrity (dump → load → dump)
- ZIP storage and restoration
- Large schema performance (10,000+ tables)

### Performance Benchmarks
- Dump time: 10,000 tables < 60 seconds
- Memory usage: < 200MB regardless of size
- Load time: Comparable to single-file

## Benefits Summary

### For Developers
✅ Easy navigation (organized directories)
✅ Fast file loads (< 500 lines per file)
✅ Find tables quickly (grep in 4_tables/)
✅ Readable git diffs

### For Code Review
✅ Only changed files in diff
✅ Small, focused changes
✅ Easy to approve
✅ Clear context

### For Git
✅ Smaller diffs (50-200 lines typical)
✅ Faster git operations
✅ Better merge resolution
✅ Reduced repository bloat

### For Performance
✅ Memory efficient (incremental writing)
✅ Scalable (handles 50,000+ objects)
✅ Fast loading (parallel-ready)
✅ No size limits

## Migration Path

### Existing Projects

**Step 1**: Generate test schema
```bash
cd integration
rails db:seed
rails db:schema:dump
# See 4,000+ line structure.sql
```

**Step 2**: Update configuration
```ruby
config.output_path = 'db/schema'
```

**Step 3**: Dump multi-file
```bash
rails db:schema:dump_better
```

**Step 4**: Verify and commit
```bash
ls -R db/schema/
git add db/schema/
git rm db/structure.sql
git commit -m "Switch to multi-file schema output"
```

## Future Enhancements

### Phase 2+ Features

**Parallel Operations**:
- Parallel file writing (3-5x speedup)
- Parallel loading (3-4x speedup for large schemas)

**Incremental Dumps**:
- Track object fingerprints
- Only regenerate changed objects
- 10-100x speedup for incremental changes

**Advanced Chunking**:
- Group by table prefix
- Group by schema
- Logical grouping vs LOC-based

**Web UI Enhancements**:
- Browse directory structure online
- View individual files without download
- File-level diff between versions
- Search within version

## Success Criteria

✅ **Functional**: Dump, load, store, restore all work correctly
✅ **Performance**: Handles 50,000+ tables in < 5 minutes, < 200MB RAM
✅ **UX**: Easy configuration, clear documentation, good error messages
✅ **Git**: Clean diffs, easy merges, no noise
✅ **Testing**: > 95% coverage, comprehensive edge cases
✅ **Documentation**: Complete guides, examples, troubleshooting

## Dependencies

**New Gem Dependency**: `rubyzip` (~> 2.3)
- For ZIP archive creation and extraction
- Pure Ruby, no system dependencies
- Well-maintained, 50M+ downloads

**Rails Compatibility**: Rails 6.0+, Ruby 2.7+, PostgreSQL 10+

## Timeline Estimate

**Phase 1** (Core Infrastructure): 2-3 weeks
**Phase 2** (Loading & Storage): 1-2 weeks
**Phase 3** (Web UI): 1 week
**Phase 4** (Testing & Docs): 1 week

**Total**: 5-7 weeks for complete implementation

## Questions & Answers

**Q: Why not use load_order array in manifest?**
A: Would contain thousands of file paths, making manifest huge. Numbered directories provide implicit load order.

**Q: Why 500 LOC limit?**
A: Balance between file count and file size. Most editors handle 500 lines easily. Git diffs stay manageable.

**Q: What if a single table has 1,000 columns?**
A: Gets dedicated file. OK to exceed limit for single large objects.

**Q: Why ZIP storage in database?**
A: Provides complete directory structure for download. Developer can extract and replace local schema instantly.

**Q: Performance impact?**
A: Minimal. Incremental writing uses less memory. Slightly more file I/O overhead (~250ms for 250 files), negligible compared to introspection time.

**Q: Backward compatible?**
A: Yes. Default remains single-file. Multi-file is opt-in via `config.output_path = 'db/schema'`.

## Conclusion

Multi-file schema output transforms BetterStructureSql from a gem that handles typical Rails schemas (10-100 tables) into one that scales to enterprise schemas (10,000+ tables) while improving developer experience through better navigation, cleaner git diffs, and easier code review.

The numbered directory approach ensures simplicity (no manifest parsing for loading) while the ZIP storage provides complete schema snapshots for version management. Migration splitting addresses the often-overlooked problem of thousands of schema_migrations entries.

All documentation is complete and ready for implementation.
