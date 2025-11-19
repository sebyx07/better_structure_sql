# Phase 4: Documentation, Testing, and Polish

## Objective

Complete documentation, comprehensive testing with large schemas, performance optimization, and final polish for production readiness.

## Deliverables

### 1. Documentation Updates

#### README.md (Project Root)

**Add section**: "Multi-File Schema Output"

```markdown
## Multi-File Schema Output

For massive database schemas with tens of thousands of tables, triggers, and functions, BetterStructureSql can split output into multiple organized files.

### Configuration

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Multi-file output (directory path)
  config.output_path = 'db/schema'

  # Chunking settings
  config.max_lines_per_file = 500        # Soft limit per file
  config.overflow_threshold = 1.1        # 10% overflow allowed

  # Versioning with ZIP storage
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```

### Directory Structure

Schema organized by object type with numeric prefixes for load order:

```
db/schema/
├── _header.sql
├── _manifest.json
├── 1_extensions/
│   └── 000001.sql
├── 2_types/
│   ├── 000001.sql
│   └── 000002.sql
├── 3_sequences/
│   └── 000001.sql
├── 4_tables/
│   ├── 000001.sql  (500 LOC max)
│   ├── 000002.sql
│   └── 000003.sql
├── 5_indexes/
│   └── 000001.sql
├── 6_foreign_keys/
│   └── 000001.sql
├── 7_views/
│   └── 000001.sql
├── 8_functions/
│   └── 000001.sql
└── 9_triggers/
    └── 000001.sql
```

### Benefits

- **Massive schema support**: Handle 50,000+ tables without memory issues
- **Better git diffs**: Only changed files show in diffs
- **Easy navigation**: Find tables quickly in organized directories
- **ZIP downloads**: Web UI provides complete directory structure as ZIP

### Loading

```bash
# Auto-detects multi-file vs single-file
rails db:schema:load_better

# Restore from stored version
rails db:schema:restore[VERSION_ID]
```

### Web UI

Browse stored schema versions at `/better_structure_sql/schema_versions`:
- View directory structure and metadata
- Download ZIP archive
- Compare versions
```

#### CLAUDE.md (Project Context)

**Add to Keywords section**:
```
multi-file schema output, directory-based dump, numbered directories, load order prefixes, 1_extensions 2_types 3_sequences 4_tables 5_indexes 6_foreign_keys 7_views 8_functions 9_triggers, chunking strategy, 500 LOC limit, overflow threshold, file splitting, numbered SQL files 000001.sql, manifest JSON, rubyzip gem, ZIP archive storage, binary column zip_archive, output_mode column, multi_file single_file, ZipGenerator class, FileWriter class, SchemaLoader class, directory tree visualization, Web UI ZIP download, extract and replace workflow, massive database schemas, tens of thousands of tables, memory efficient chunking, incremental file writing, dependency-safe ordering, topological load order
```

**Add to Component Architecture section**:
```markdown
**FileWriter** - Multi-file output management
- Detect output mode (file vs directory)
- Chunk sections into 500 LOC files
- Create numbered directories with load-order prefixes
- Write files incrementally for memory efficiency

**ManifestGenerator** - Metadata for multi-file dumps
- Calculate statistics (files, lines, breakdown)
- Generate load order respecting dependencies
- JSON format for tooling integration

**ZipGenerator** - ZIP archive creation and extraction
- Uses rubyzip for in-memory ZIP operations
- Create from directory or file map
- Extract with path traversal protection
- Validation for ZIP bombs

**SchemaLoader** - Multi-format schema loading
- Auto-detect file vs directory
- Load multi-file using manifest order
- Stream large files
- Support restoration from stored versions
```

#### Feature Documentation

**File**: `docs/features/multi-file-schema-output/USAGE.md` (new)

**Content**:
```markdown
# Multi-File Schema Output - Usage Guide

## When to Use Multi-File Output

Use multi-file output when:
- Schema exceeds 10,000 lines
- More than 1,000 database objects
- Single file causes editor performance issues
- Team needs to review schema changes frequently
- Git diffs are too large to be useful

## Configuration

### Basic Setup

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'
end
```

### Advanced Options

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'

  # Adjust chunk size
  config.max_lines_per_file = 500        # Default: 500
  config.overflow_threshold = 1.1        # Default: 1.1 (10%)

  # Manifest generation
  config.generate_manifest = true        # Default: true

  # Versioning
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```

## Directory Structure

### Numbered Directories

Directories are prefixed with numbers indicating load order:

1. `1_extensions/` - PostgreSQL extensions
2. `2_types/` - Custom types (enums, composites, domains)
3. `3_sequences/` - Sequences
4. `4_tables/` - Tables with columns and constraints
5. `5_indexes/` - Indexes
6. `6_foreign_keys/` - Foreign key constraints
7. `7_views/` - Views and materialized views
8. `8_functions/` - User-defined functions
9. `9_triggers/` - Triggers

### File Naming

Files within directories: `000001.sql`, `000002.sql`, etc.

Example:
```
4_tables/
├── 000001.sql  (users, posts, comments)
├── 000002.sql  (orders, products, categories)
└── 000003.sql  (large_table with 600 columns)
```

### Special Files

- `_header.sql` - SET statements and search path
- `_manifest.json` - Metadata and load order

## Chunking Behavior

### 500 LOC Soft Limit

Files target 500 lines with 10% overflow tolerance:

**Scenario 1**: Accumulate small objects
```
Current: 450 lines
Next object: 40 lines
Total: 490 lines (under 550 threshold)
→ Add to current file
```

**Scenario 2**: Overflow triggers new file
```
Current: 450 lines
Next object: 120 lines
Total: 570 lines (over 550 threshold)
→ New file for object
```

**Scenario 3**: Large single object
```
Next object: 650 lines (huge table)
→ Dedicated file (OK to exceed limit)
```

## Dumping Schema

### Command

```bash
rails db:schema:dump_better
```

### Output

```
Schema dumped to 247 files in db/schema
```

### Verify

```bash
ls -R db/schema
cat db/schema/_manifest.json | jq .
```

## Loading Schema

### Command

```bash
rails db:schema:load_better
```

### Manual Load

```bash
# Using manifest
jq -r '.load_order[]' db/schema/_manifest.json | \
  xargs -I {} psql -d myapp_development -f "db/schema/{}"
```

## Schema Versioning

### Store Current Schema

```bash
rails db:schema:store
```

Stores both:
- Combined content (single text blob)
- ZIP archive (complete directory structure)

### List Versions

```bash
rails db:schema:versions
```

Output:
```
ID  Format  Mode        PG Version  Files  Size     Created
--  ------  ----------  ----------  -----  -------  -------------------
5   SQL     Multi-File  14.5        247    1.2 MB   2025-11-19 10:30:00
4   SQL     Multi-File  14.5        238    1.1 MB   2025-11-18 15:20:00
3   SQL     Single File 14.5        1      500 KB   2025-11-17 09:00:00
```

### Restore Version

```bash
rails db:schema:restore[5]
```

Process:
1. Extracts ZIP to temp directory
2. Loads files in manifest order
3. Cleans up temp directory

## Web UI

### Access

Navigate to: `http://localhost:3000/better_structure_sql/schema_versions`

### Features

**Index Page**:
- List all stored versions
- See file counts and sizes
- One-click download

**Show Page**:
- View directory tree
- See breakdown by type
- View load order
- Download ZIP

**Download**:
- Click "Download ZIP Archive"
- Extract locally
- Replace `db/schema/` directory

## Git Workflow

### Initial Setup

```bash
# Dump multi-file schema
rails db:schema:dump_better

# Add to git
git add db/schema/
git rm db/structure.sql  # If migrating from single file
git commit -m "Switch to multi-file schema output"
```

### Making Changes

```bash
# Make schema changes
rails generate migration AddUsersTable

# Run migration
rails db:migrate

# Dump schema
rails db:schema:dump_better

# Review changes
git status  # Shows only affected files
git diff db/schema/

# Commit
git add db/schema/
git commit -m "Add users table"
```

### Code Review

Reviewer sees only changed files:
```
db/schema/4_tables/000042.sql  (new file)
db/schema/5_indexes/000018.sql (modified)
```

## Troubleshooting

### Issue: "Manifest not found"

**Cause**: Directory missing `_manifest.json`

**Solution**:
```bash
# Re-dump schema
rails db:schema:dump_better
```

### Issue: Files in wrong order

**Cause**: Manual file modification

**Solution**:
```bash
# Dump fresh schema
rm -rf db/schema/
rails db:schema:dump_better
```

### Issue: Large file exceeds 500 LOC

**Answer**: This is OK! Single large objects (600+ column table, complex trigger) get dedicated files.

### Issue: Want larger chunks

**Solution**:
```ruby
config.max_lines_per_file = 1000  # Increase limit
```

## Performance Tips

### Large Schemas (50,000+ tables)

- Use multi-file output (memory efficient)
- Increase `max_lines_per_file` to reduce file count
- Consider disabling optional features:

```ruby
config.include_functions = false  # Skip if not using
config.include_triggers = false   # Skip if not using
```

### Git Performance

- Keep file counts reasonable (< 500 files ideal)
- Use larger `max_lines_per_file` if needed
- Regular cleanup of old schema versions

## Migration from Single File

### Step 1: Update Configuration

```ruby
# Before
config.output_path = 'db/structure.sql'

# After
config.output_path = 'db/schema'
```

### Step 2: Dump

```bash
rails db:schema:dump_better
```

### Step 3: Verify

```bash
ls -R db/schema
cat db/schema/_manifest.json | jq .
```

### Step 4: Test Load

```bash
# Fresh database
rails db:drop db:create

# Load multi-file
rails db:schema:load_better

# Verify tables
rails console
> ApplicationRecord.connection.tables
```

### Step 5: Commit

```bash
git add db/schema/
git rm db/structure.sql
git commit -m "Migrate to multi-file schema output"
```

### Rollback (if needed)

```ruby
# Revert config
config.output_path = 'db/structure.sql'
```

```bash
rails db:schema:dump_better
git rm -rf db/schema/
git add db/structure.sql
git commit -m "Revert to single-file schema"
```
```

### 2. Comprehensive Testing

#### Large Schema Generator

**File**: `spec/support/large_schema_generator.rb`

**Purpose**: Generate test schemas with thousands of objects

```ruby
module LargeSchemaGenerator
  def self.generate(tables: 1000, indexes_per_table: 3, triggers_per_table: 1)
    connection = ActiveRecord::Base.connection

    tables.times do |i|
      table_name = "test_table_#{i.to_s.rjust(6, '0')}"

      connection.create_table table_name do |t|
        t.string :name
        t.text :description
        t.integer :status
        t.timestamps
      end

      # Add indexes
      indexes_per_table.times do |j|
        connection.add_index table_name, :name, name: "idx_#{table_name}_name_#{j}"
      end

      # Add triggers
      triggers_per_table.times do |j|
        connection.execute <<~SQL
          CREATE TRIGGER trg_#{table_name}_#{j}
          BEFORE INSERT ON #{table_name}
          FOR EACH ROW
          EXECUTE FUNCTION update_timestamp();
        SQL
      end
    end
  end

  def self.cleanup
    connection = ActiveRecord::Base.connection
    connection.tables.select { |t| t.start_with?('test_table_') }.each do |table|
      connection.drop_table table
    end
  end
end
```

#### Performance Benchmarks

**File**: `spec/performance/multi_file_dump_spec.rb`

```ruby
require 'benchmark'

describe "Multi-file dump performance" do
  it "dumps 10,000 tables in under 60 seconds" do
    LargeSchemaGenerator.generate(tables: 10_000)

    elapsed = Benchmark.realtime do
      BetterStructureSql::Dumper.new.dump
    end

    expect(elapsed).to be < 60
    expect(Dir['db/schema/**/*.sql'].count).to be > 0
  end

  it "uses less than 200MB memory" do
    LargeSchemaGenerator.generate(tables: 10_000)

    memory_before = get_memory_usage
    BetterStructureSql::Dumper.new.dump
    memory_after = get_memory_usage

    memory_increase = memory_after - memory_before
    expect(memory_increase).to be < 200.megabytes
  end

  it "creates appropriate file counts" do
    LargeSchemaGenerator.generate(tables: 10_000)

    BetterStructureSql::Dumper.new.dump

    files = Dir['db/schema/**/*.sql']
    expect(files.count).to be > 100  # Many files
    expect(files.count).to be < 500  # But not too many
  end

  def get_memory_usage
    `ps -o rss= -p #{Process.pid}`.to_i * 1024  # Convert KB to bytes
  end
end
```

#### Integration Tests

**File**: `spec/integration/complete_workflow_spec.rb`

```ruby
describe "Complete multi-file workflow", integration: true do
  it "handles full dump → store → download → restore cycle" do
    # Setup
    create_test_schema(tables: 100)
    BetterStructureSql.configure do |config|
      config.output_path = 'db/schema'
      config.enable_schema_versions = true
    end

    # Dump
    dumper.dump(store_version: true)
    expect(Dir.exist?('db/schema')).to eq(true)

    # Verify storage
    version = SchemaVersion.last
    expect(version.output_mode).to eq('multi_file')
    expect(version.has_zip_archive?).to eq(true)

    # Download ZIP (simulate Web UI)
    zip_data = version.zip_archive
    expect(zip_data).to be_present

    # Extract ZIP
    temp_dir = 'tmp/extracted_schema'
    ZipGenerator.extract_to_directory(zip_data, temp_dir)
    expect(File.exist?("#{temp_dir}/_manifest.json")).to eq(true)

    # Drop all tables
    drop_all_tables

    # Load from extracted directory
    loader = SchemaLoader.new
    loader.load(temp_dir)

    # Verify tables restored
    expect(ApplicationRecord.connection.tables.count).to be > 0

    # Cleanup
    FileUtils.rm_rf(temp_dir)
  end
end
```

### 3. Gemspec Updates

**File**: `better_structure_sql.gemspec`

**Add rubyzip dependency**:
```ruby
spec.add_dependency 'rubyzip', '~> 2.3'
```

**Update description**:
```ruby
spec.description = <<~DESC
  Pure Ruby PostgreSQL schema dumper for Rails applications. Generates clean,
  deterministic structure.sql files without pg_dump dependency. Supports both
  single-file and multi-file output for massive schemas with tens of thousands
  of database objects. Includes schema versioning with ZIP storage and web UI.
DESC
```

### 4. Generator Template Updates

**File**: `lib/generators/better_structure_sql/install_generator.rb`

**Update instructions**:
```ruby
def show_instructions
  say "\n" + ("=" * 70)
  say "BetterStructureSql installed successfully!", :green
  say ("=" * 70)

  say "\nNext steps:"
  say "1. Review config/initializers/better_structure_sql.rb"
  say "2. Run: rails db:migrate  (creates schema_versions table)"
  say "3. Run: rails db:schema:dump_better"
  say "\nFor multi-file output:"
  say "   config.output_path = 'db/schema'  # Directory for split files"
  say "\nFor single-file output (default):"
  say "   config.output_path = 'db/structure.sql'"
  say "\nDocumentation: https://github.com/yourusername/better_structure_sql"
  say ("=" * 70) + "\n"
end
```

### 5. Error Messages and Logging

**File**: `lib/better_structure_sql/file_writer.rb`

**Add informative logging**:
```ruby
def write_multi_file(base_path, sections)
  start_time = Time.now
  file_count = 0
  total_lines = 0

  sections.each do |section_name, objects|
    next if objects.empty?

    dir_name = directory_name_for_section(section_name)
    chunks = chunk_section(objects, @config.max_lines_per_file)

    chunks.each_with_index do |chunk, index|
      filename = format_filename(index + 1)
      write_chunk(File.join(base_path, dir_name), filename, chunk.join("\n\n"))

      file_count += 1
      total_lines += chunk.sum { |obj| obj.lines.count }
    end

    Rails.logger.info "Wrote #{chunks.count} file(s) for #{section_name}"
  end

  # Write manifest
  manifest = ManifestGenerator.new(@config).generate(file_map, @config)
  File.write(File.join(base_path, '_manifest.json'), manifest)

  elapsed = Time.now - start_time
  Rails.logger.info "Multi-file dump complete: #{file_count} files, #{total_lines} lines in #{elapsed.round(2)}s"

  file_count
end
```

## Testing Requirements

### Unit Tests

- All existing tests pass
- New classes have > 95% coverage
- Edge cases documented and tested

### Integration Tests

- Full workflow tests
- Large schema tests (10,000+ tables)
- Performance benchmarks
- Round-trip integrity tests

### Manual Testing

**Checklist**:
- [ ] Dump schema with 0 tables (empty database)
- [ ] Dump schema with 1 table
- [ ] Dump schema with 10,000 tables
- [ ] Single large table (600+ columns)
- [ ] Load multi-file schema successfully
- [ ] Store version and download ZIP from Web UI
- [ ] Extract ZIP and verify directory structure
- [ ] Restore from stored version
- [ ] Migrate from single-file to multi-file
- [ ] Rollback from multi-file to single-file

## Success Criteria

### Functional Requirements

✅ **Complete feature set**:
- Multi-file dump with numbered directories
- 500 LOC chunking with overflow handling
- ZIP storage in database
- Web UI download
- Schema loading from multi-file
- Version restoration

✅ **Documentation**:
- README updated with multi-file section
- Usage guide created
- CLAUDE.md updated with keywords
- Code comments for all public methods

✅ **Testing**:
- > 95% test coverage
- Performance benchmarks pass
- Integration tests cover full workflow

### Performance Requirements

✅ **Dump performance**:
- 10,000 tables in < 60 seconds
- 50,000 tables in < 5 minutes
- Memory usage < 200MB

✅ **Load performance**:
- Multi-file load comparable to single-file
- ZIP extraction < 2 seconds for typical schemas

✅ **Web UI**:
- Index page loads in < 500ms
- Show page loads in < 200ms
- ZIP download starts in < 1 second

### Code Quality

✅ **Maintainability**:
- Clear separation of concerns
- Documented public APIs
- Error messages are actionable
- Logging provides insight

## Dependencies

**Requires**:
- Phase 1: Core multi-file output
- Phase 2: Schema loading and ZIP storage
- Phase 3: Web UI integration

**Completes**: Full multi-file schema output feature

## Future Enhancements

### Performance Optimizations

**Parallel file writing**:
- Write independent sections concurrently
- 3-5x speedup potential

**Incremental dumps**:
- Track object fingerprints
- Only regenerate changed objects
- 10-100x speedup for incremental changes

### Advanced Features

**Custom chunking strategies**:
- Group by table prefix
- Group by schema
- Logical grouping vs LOC-based

**File-level browsing in Web UI**:
- Click file to view content
- Syntax highlighting
- Search within version

**Schema comparison**:
- Diff two versions at file level
- Highlight changed objects
- Migration script generation

**Export formats**:
- GraphQL schema export
- OpenAPI schema export
- Documentation generation

## Documentation Deliverables

**Created**:
- [x] `docs/features/multi-file-schema-output/README.md`
- [x] `docs/features/multi-file-schema-output/architecture.md`
- [x] `docs/features/multi-file-schema-output/plan/phase-1.md`
- [x] `docs/features/multi-file-schema-output/plan/phase-2.md`
- [x] `docs/features/multi-file-schema-output/plan/phase-3.md`
- [x] `docs/features/multi-file-schema-output/plan/phase-4.md`
- [x] `docs/features/multi-file-schema-output/USAGE.md`

**Updated**:
- [ ] `README.md` - Add multi-file section
- [ ] `CLAUDE.md` - Add keywords and components
