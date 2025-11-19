# Multi-File Schema Output - Architecture

## Overview

Technical architecture for splitting large database schemas into multiple files organized by object type, while maintaining single-blob storage for versioning.

## Design Principles

1. **Backward Compatible**: Single-file output remains default, multi-file opt-in via configuration
2. **Dependency Safe**: File ordering must respect PostgreSQL object dependencies
3. **Incremental Writing**: Write files as generated to minimize memory usage
4. **Deterministic**: Same schema always produces identical file structure
5. **Verifiable**: Manifest provides metadata for validation and loading

## Component Architecture

### New Components

#### 1. FileWriter (New)

**Responsibility**: Manage multi-file output with chunking logic

**Location**: `lib/better_structure_sql/file_writer.rb`

**Interface**:
```ruby
class FileWriter
  def initialize(config)
  def write_single_file(path, content)      # Current behavior
  def write_multi_file(base_path, sections) # New behavior
  def detect_output_mode(path)              # File vs directory
end
```

**Key Methods**:

`write_multi_file(base_path, sections)`:
- Creates directory structure
- Chunks each section into files
- Writes manifest
- Returns file count

`chunk_section(section_name, objects, max_lines)`:
- Splits objects across multiple files
- Implements 500 LOC soft limit with overflow
- Handles single large objects (600+ LOC)
- Returns array of file chunks

`write_chunk(directory, filename, content)`:
- Writes individual SQL file
- Ensures directory exists
- Sets file permissions (0644)

**Chunking Algorithm**:
```ruby
def chunk_section(objects, max_lines)
  chunks = []
  current_chunk = []
  current_lines = 0

  objects.each do |obj|
    obj_lines = obj.split("\n").count

    # Single large object → dedicated file
    if obj_lines > max_lines
      chunks << current_chunk unless current_chunk.empty?
      chunks << [obj]  # Dedicated file
      current_chunk = []
      current_lines = 0
      next
    end

    # Check overflow (10% threshold)
    overflow_threshold = max_lines * 1.1
    would_overflow = (current_lines + obj_lines) > overflow_threshold

    if would_overflow && current_lines > 0
      chunks << current_chunk
      current_chunk = [obj]
      current_lines = obj_lines
    else
      current_chunk << obj
      current_lines += obj_lines
    end
  end

  chunks << current_chunk unless current_chunk.empty?
  chunks
end
```

#### 2. ManifestGenerator (New)

**Responsibility**: Generate metadata about multi-file structure

**Location**: `lib/better_structure_sql/manifest_generator.rb`

**Purpose**: Provide statistics and metadata for tooling, NOT for determining load order (which is implicit from numbered directories)

**Interface**:
```ruby
class ManifestGenerator
  def initialize(config)
  def generate(file_map)  # Returns JSON string
  def parse(json)         # Returns hash
end
```

**Output Format**:
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
    "4_tables": {"files": 156, "lines": 78432},
    "5_indexes": {"files": 45, "lines": 9821},
    "migrations": {"files": 3, "lines": 1520}
  }
}
```

**Note**: No `load_order` array - load order is implicit from numbered directory names (1_, 2_, etc.) and numeric filenames. This keeps manifest small even with thousands of files.

#### 3. SchemaLoader (New)

**Responsibility**: Load multi-file schemas in correct order

**Location**: `lib/better_structure_sql/schema_loader.rb`

**Interface**:
```ruby
class SchemaLoader
  def initialize(config)
  def load(path)          # Auto-detects file vs directory
  def load_directory(dir) # Loads multi-file using manifest
  def load_file(file)     # Loads single file (current behavior)
end
```

**Load Strategy**:
1. Check if path is file or directory
2. If directory:
   - Load `_header.sql` first
   - Iterate through numbered directories in order (1_, 2_, 3_...)
   - Within each directory, load files in numeric order (000001.sql, 000002.sql...)
   - Load `migrations/` last
   - Execute each file's SQL
3. If file:
   - Load as single SQL file (existing behavior)

**Load Order Algorithm**:
```ruby
def load_directory(dir_path)
  connection = ActiveRecord::Base.connection

  # Load header first
  connection.execute(File.read(File.join(dir_path, '_header.sql')))

  # Load numbered directories in order (one execute per directory)
  Dir.glob(File.join(dir_path, '{1..9}_*')).sort.each do |dir|
    # Concatenate all files in directory
    sql = Dir.glob(File.join(dir, '*.sql')).sort.map { |f| File.read(f) }.join("\n\n")

    # Execute entire directory as single SQL statement
    connection.execute(sql) unless sql.empty?
  end

  # Load migrations last (all files concatenated)
  migrations_dir = File.join(dir_path, 'migrations')
  if Dir.exist?(migrations_dir)
    sql = Dir.glob(File.join(migrations_dir, '*.sql')).sort.map { |f| File.read(f) }.join("\n\n")
    connection.execute(sql) unless sql.empty?
  end
end
```

**Loading Strategy**:
- **One directory = One SQL execution**
- Concatenate all files within directory before executing
- Memory efficient: Load one directory at a time, not all files
- Example: 4_tables/ with 150 files → concatenate all 150 → execute once

**Benefits**:
- Fewer database round-trips (11 executes max: header + 9 dirs + migrations)
- Transactional integrity per directory
- Memory footprint: ~1-2MB per directory (not entire schema)

**No manifest dependency**: Numbered directories ensure correct order without parsing JSON.

#### 4. ZipGenerator (New)

**Responsibility**: Generate ZIP archives from multi-file content

**Location**: `lib/better_structure_sql/zip_generator.rb`

**Dependency**: `rubyzip` gem

**Interface**:
```ruby
class ZipGenerator
  def self.generate(content, format_type)
  def self.create_from_directory(dir_path)
end
```

**Usage**:
```ruby
# From stored blob (Web UI download)
zip_data = ZipGenerator.generate(version.content, version.format_type)
send_data zip_data, filename: "schema.zip", type: 'application/zip'

# From local directory
zip_data = ZipGenerator.create_from_directory('db/schema')
```

**Implementation**:
```ruby
def self.generate(content, format_type)
  require 'zip'

  # Parse content to extract file structure
  file_map = parse_multi_file_content(content)

  # Create in-memory ZIP
  buffer = Zip::OutputStream.write_buffer do |zip|
    file_map.each do |path, content|
      zip.put_next_entry(path)
      zip.write content
    end
  end

  buffer.string
end
```

### Modified Components

#### 1. Dumper (Modified)

**Changes**:
- Detect output mode (file vs directory) from `config.output_path`
- Delegate file writing to `FileWriter`
- Return metadata about files written

**New Flow**:
```ruby
def dump(store_version: nil)
  validate_configuration!

  # Generate sections (unchanged)
  sections = generate_all_sections

  # Determine output mode
  output_mode = detect_output_mode(config.output_path)

  case output_mode
  when :single_file
    content = format_sections(sections)
    FileWriter.write_single_file(config.output_path, content)
    store_version!(content) if store_version
  when :multi_file
    file_count = FileWriter.write_multi_file(config.output_path, sections)

    # Combine for storage
    content = combine_sections(sections) if store_version
    store_version!(content) if store_version

    puts "Schema dumped to #{file_count} files in #{config.output_path}"
  end
end

def detect_output_mode(path)
  # No extension → directory → multi_file
  # Has extension (.sql, .rb) → file → single_file
  File.extname(path).empty? ? :multi_file : :single_file
end
```

**Section Generation** (unchanged):
- Each section method returns array of SQL strings
- Example: `tables_section` returns `["CREATE TABLE users...", "CREATE TABLE posts..."]`

**Multi-File Storage**:
- Combine all sections into single string for database storage
- Inject manifest as JSON comment at top
- Web UI detects manifest to enable ZIP download

#### 2. Configuration (Modified)

**New Options**:
```ruby
attr_accessor :max_lines_per_file      # Default: 500
attr_accessor :overflow_threshold      # Default: 1.1 (10%)
attr_accessor :generate_manifest       # Default: true
```

**Validation**:
```ruby
def validate!
  # Existing validations...

  raise ConfigurationError, "max_lines_per_file must be positive" if max_lines_per_file <= 0
  raise ConfigurationError, "overflow_threshold must be >= 1.0" if overflow_threshold < 1.0
end
```

**Backward Compatibility**:
- All new options have sensible defaults
- Existing configs work without changes

#### 3. SchemaVersion Model (Modified)

**Changes**: Minimal - storage format unchanged

**New Method**:
```ruby
def multi_file_format?
  content.start_with?('-- MANIFEST:')
end
```

**Storage Format**:

**Single-file** (existing):
```sql
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
...
```

**Multi-file** (new):
```sql
-- MANIFEST: {"version": "1.0", "total_files": 247, ...}
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
...
```

Manifest injected as SQL comment at top, allows detection and extraction.

#### 4. SchemaVersionsController (Modified)

**New Action**:
```ruby
def download
  version = SchemaVersion.find(params[:id])

  if version.multi_file_format?
    send_zip_download(version)
  else
    send_file_download(version)
  end
end

private

def send_zip_download(version)
  zip_data = ZipGenerator.generate(version.content, version.format_type)

  send_data zip_data,
            filename: "schema_version_#{version.id}_#{version.created_at.to_i}.zip",
            type: 'application/zip',
            disposition: 'attachment'
end

def send_file_download(version)
  # Existing behavior
  extension = version.format_type == 'rb' ? 'rb' : 'sql'
  send_data version.content,
            filename: "structure.#{extension}",
            type: 'text/plain',
            disposition: 'attachment'
end
```

**Show Action** (modified):
```ruby
def show
  @schema_version = SchemaVersion.find(params[:id])

  if @schema_version.multi_file_format?
    @manifest = extract_manifest(@schema_version.content)
    render 'show_multi_file'
  else
    # Existing behavior
    render 'show'
  end
end
```

#### 5. Rake Tasks (Modified)

**db:schema:load_better**:
```ruby
task load_better: :environment do
  config = BetterStructureSql.configuration
  loader = BetterStructureSql::SchemaLoader.new(config)

  loader.load(config.output_path)
  puts "Schema loaded from #{config.output_path}"
end
```

Auto-detects file vs directory, loads appropriately.

## Data Flow

### Dump Flow (Multi-File)

```
User runs: rails db:schema:dump_better
↓
Railtie → Dumper.dump
↓
Dumper#dump
  ├─ validate_configuration!
  ├─ detect_output_mode → :multi_file
  ├─ generate_all_sections → {extensions: [...], tables: [...], ...}
  ├─ FileWriter.write_multi_file
  │    ├─ create_directory_structure
  │    ├─ chunk_section('tables', tables, 500)
  │    │    └─ [chunk1, chunk2, chunk3, ...]
  │    ├─ write_files (extensions/000001.sql, tables/000001.sql, ...)
  │    └─ ManifestGenerator.generate → _manifest.json
  ├─ combine_sections (if storing version)
  │    └─ Inject manifest as comment at top
  └─ SchemaVersions.store_current (if enabled)
       └─ Save combined content to database
```

### Load Flow (Multi-File)

```
User runs: rails db:schema:load_better
↓
Railtie → SchemaLoader.load
↓
SchemaLoader#load
  ├─ detect_mode(path) → :multi_file
  ├─ read_manifest(path/_manifest.json)
  ├─ manifest.load_order.each do |file|
  │    ├─ read SQL file
  │    └─ execute via ActiveRecord connection
  │ end
  └─ success!
```

### Download Flow (Web UI)

```
User clicks: "Download" on schema version
↓
GET /schema_versions/:id/download
↓
SchemaVersionsController#download
  ├─ version = SchemaVersion.find(params[:id])
  ├─ version.multi_file_format? → true
  ├─ ZipGenerator.generate(version.content)
  │    ├─ extract_manifest from content
  │    ├─ parse content into file chunks
  │    ├─ create in-memory ZIP using rubyzip
  │    │    ├─ add _header.sql
  │    │    ├─ add _manifest.json
  │    │    ├─ add extensions/000001.sql
  │    │    └─ add tables/000001.sql, ...
  │    └─ return ZIP binary data
  └─ send_data(zip_data, filename: "schema_version_123.zip")
```

## File Structure Details

### Directory Organization

```
db/schema/                      (config.output_path)
├── _header.sql                 (12 lines - SET statements)
├── _manifest.json              (metadata)
├── extensions/
│   └── 000001.sql             (1 file, 12 lines)
├── types/
│   ├── 000001.sql             (450 lines - enums/composites)
│   └── 000002.sql             (130 lines)
├── sequences/
│   ├── 000001.sql             (480 lines)
│   └── 000002.sql             (320 lines)
├── tables/
│   ├── 000001.sql             (498 lines - 15 tables)
│   ├── 000002.sql             (503 lines - 14 tables)
│   ├── 000003.sql             (620 lines - 1 huge table, 600 columns)
│   └── 000004.sql             (412 lines - 12 tables)
├── indexes/
│   ├── 000001.sql             (499 lines)
│   └── 000002.sql             (301 lines)
├── foreign_keys/
│   └── 000001.sql             (234 lines)
├── views/
│   └── 000001.sql             (89 lines)
├── functions/
│   ├── 000001.sql             (487 lines)
│   └── 000002.sql             (650 lines - single complex function)
└── triggers/
    └── 000001.sql             (123 lines)
```

### Dependency Order

Files are numbered and ordered to respect PostgreSQL dependencies:

1. **_header.sql** - SET statements, search path
2. **extensions/** - Required by types and functions
3. **types/** - Required by tables
4. **sequences/** - Required by table defaults
5. **tables/** - Foundation for everything else
6. **indexes/** - Require tables
7. **foreign_keys/** - Require all tables to exist
8. **views/** - May depend on tables (topologically sorted)
9. **materialized_views/** - Same as views
10. **functions/** - May depend on types (topologically sorted)
11. **triggers/** - Require functions and tables

Within each directory, files are numbered in safe order (existing Dumper logic).

## Chunking Algorithm Details

### Core Logic

```ruby
MAX_LINES = 500
OVERFLOW_THRESHOLD = 1.1  # 10% allowed overflow

def should_create_new_file?(current_lines, object_lines)
  # Single large object always gets dedicated file (even if > MAX)
  return true if object_lines > MAX_LINES

  # Would overflow threshold?
  total = current_lines + object_lines
  total > (MAX_LINES * OVERFLOW_THRESHOLD)
end
```

### Examples

**Example 1**: Small objects chunking
```
Current file: 450 lines
Next object: 40 lines
Total: 490 lines (under 550 threshold)
→ Add to current file
```

**Example 2**: Overflow triggers new file
```
Current file: 450 lines
Next object: 150 lines
Total: 600 lines (over 550 threshold)
→ Create new file, add object there
```

**Example 3**: Large single object
```
Current file: 200 lines
Next object: 650 lines (huge table with 600 columns)
Total: 850 lines
→ Close current file, put 650-line object in dedicated file
File ends up with 650 lines (OK - single object exception)
```

**Example 4**: Series of medium objects
```
File 1: objects totaling 498 lines
Next object: 80 lines
Total: 578 (over 550)
→ New file

File 2: 80 + 120 + 95 + 180 = 475 lines
Next object: 90 lines
Total: 565 (over 550)
→ New file

File 3: 90 + 200 + 150 = 440 lines
(last objects)
→ End of section
```

### Edge Cases

**Empty section**: No files created (directory omitted)

**Single object > 500 LOC**: Dedicated file created, OK to exceed limit

**Last chunk < 100 lines**: Still written (no minimum size requirement)

**Object exactly 500 LOC**: Treated as large object, gets dedicated file

## Storage Format in Database

### Single Blob with Embedded Manifest

Schema versions continue to store as single `TEXT` blob, but for multi-file dumps we inject manifest as SQL comment:

```sql
-- MANIFEST: {"version":"1.0","total_files":247,"directories":{...},"load_order":[...]}
-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Types
CREATE TYPE order_status AS ENUM ('pending', 'shipped', 'delivered');

-- Tables
CREATE TABLE users (
  id bigint PRIMARY KEY,
  ...
);
...
```

**Benefits**:
- No database schema changes required
- Backward compatible (old versions work as-is)
- Self-describing format
- Web UI can extract manifest for metadata display
- ZIP generation can parse file boundaries from manifest

**Detection**:
```ruby
def multi_file_format?
  content.start_with?('-- MANIFEST:')
end
```

**Extraction**:
```ruby
def extract_manifest(content)
  first_line = content.lines.first
  return nil unless first_line.start_with?('-- MANIFEST:')

  json_str = first_line.sub(/^-- MANIFEST: /, '')
  JSON.parse(json_str)
end
```

## Performance Characteristics

### Memory Usage

**Single-file approach** (current):
- Peak: ~5x schema size (building, formatting, writing)
- 500KB schema → 2.5MB peak

**Multi-file approach** (new):
- Peak: ~2x chunk size
- 500 LOC chunks → 50KB peak per chunk
- Total: 100-200KB peak for any schema size

### I/O Performance

**File operations**:
- 247 files for 98,543 lines example
- ~1ms per file on modern SSD
- Total: ~250ms file I/O overhead
- Negligible compared to introspection time (5-10 seconds)

**Parallel writing** (future optimization):
- Independent sections can be written concurrently
- Potential 3-5x speedup for large schemas

### Git Performance

**Benefits**:
- Smaller diffs (only changed files)
- Faster `git status` (fewer lines to process)
- Better merge resolution (file-level conflicts)

**Measurements** (estimated):
- Single 100K-line file: `git diff` ~2 seconds
- 200 files averaging 500 lines: `git diff` ~0.5 seconds

## Security Considerations

### Path Traversal

**Validation**:
```ruby
def sanitize_filename(name)
  # Remove any directory separators
  name.gsub(/[\/\\]/, '_')
end

def validate_output_path(path)
  # Ensure path doesn't escape configured directory
  expanded = File.expand_path(path)
  base = File.expand_path(config.output_path)

  raise SecurityError unless expanded.start_with?(base)
end
```

### ZIP Security

**rubyzip configuration**:
```ruby
Zip.on_exists_proc = true  # Overwrite on conflict
Zip.continue_on_exists_proc = false
Zip.warn_invalid_date = false
Zip.validate_entry_sizes = true  # Prevent zip bombs
```

**Limits**:
```ruby
MAX_FILES_IN_ZIP = 10_000
MAX_UNCOMPRESSED_SIZE = 100.megabytes

def validate_zip_safety!(file_count, total_size)
  raise ZipError, "Too many files" if file_count > MAX_FILES_IN_ZIP
  raise ZipError, "Content too large" if total_size > MAX_UNCOMPRESSED_SIZE
end
```

### File Permissions

**Output files**: 0644 (owner write, all read)
**Directories**: 0755 (owner write, all read+execute)

```ruby
FileUtils.mkdir_p(dir, mode: 0755)
File.write(path, content, mode: 0644)
```

## Testing Strategy

### Unit Tests

**FileWriter**:
- Chunking logic with various object sizes
- Overflow threshold calculations
- Large object handling
- File numbering and paths

**ManifestGenerator**:
- JSON generation with correct metadata
- Load order accuracy
- Parsing and validation

**ZipGenerator**:
- In-memory ZIP creation
- File structure within ZIP
- Binary data correctness

**SchemaLoader**:
- Directory detection
- Manifest parsing
- Load order execution
- Error handling

### Integration Tests

**Full dump cycle**:
```ruby
it "dumps large schema to multiple files" do
  # Create schema with 10,000 tables
  create_large_schema(tables: 10_000)

  BetterStructureSql.configure do |config|
    config.output_path = 'db/schema'
    config.max_lines_per_file = 500
  end

  dumper.dump

  # Verify files exist
  expect(Dir["db/schema/**/*.sql"].count).to be > 100

  # Verify manifest
  manifest = JSON.parse(File.read('db/schema/_manifest.json'))
  expect(manifest['total_files']).to eq(Dir["db/schema/**/*.sql"].count)

  # Verify load order respects dependencies
  loader.load('db/schema')

  # Schema should be identical
  expect { ApplicationRecord.connection.tables }.not_to raise_error
end
```

**Round-trip test**:
```ruby
it "produces identical schema after load" do
  # Original dump
  dumper.dump
  original_structure = capture_schema_structure

  # Load into fresh database
  reset_database!
  loader.load('db/schema')

  # Dump again
  dumper.dump(output_path: 'db/schema2')

  # Compare file contents
  expect(dir_contents('db/schema')).to eq(dir_contents('db/schema2'))
end
```

### Performance Tests

**Large schema benchmarks**:
```ruby
it "dumps 50,000 tables within 30 seconds" do
  create_large_schema(tables: 50_000)

  elapsed = Benchmark.realtime { dumper.dump }

  expect(elapsed).to be < 30
end

it "uses less than 200MB memory for any schema size" do
  create_large_schema(tables: 100_000)

  memory_before = get_memory_usage
  dumper.dump
  memory_after = get_memory_usage

  memory_increase = memory_after - memory_before
  expect(memory_increase).to be < 200.megabytes
end
```

## Migration Path

### For Existing Projects

**Step 1**: Update configuration
```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'  # Change from 'db/structure.sql'
  config.max_lines_per_file = 500
  config.generate_manifest = true
end
```

**Step 2**: Dump new format
```bash
rails db:schema:dump_better
```

**Step 3**: Commit multi-file structure
```bash
git add db/schema/
git rm db/structure.sql
git commit -m "Switch to multi-file schema output"
```

**Step 4**: Update CI/CD
```bash
# In CI scripts, change:
# rails db:schema:load
# to:
rails db:schema:load_better
```

### Rollback Procedure

**Revert to single file**:
```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/structure.sql'  # Back to file
end
```

```bash
rails db:schema:dump_better
git rm -rf db/schema/
git add db/structure.sql
git commit -m "Revert to single-file schema"
```

## Gem Dependencies

### New Dependency: rubyzip

**Gemspec addition**:
```ruby
spec.add_dependency 'rubyzip', '~> 2.3'
```

**Why rubyzip**:
- Pure Ruby, no system dependencies
- Well-maintained (50M+ downloads)
- Supports in-memory ZIP generation
- Rails-compatible license (BSD-2-Clause)

**Alternative considered**: `zip` gem
- Reason not chosen: Less maintained, fewer features

### Version Constraints

**Rails**: `>= 6.0`
**Ruby**: `>= 2.7`
**PostgreSQL**: `>= 10`
**rubyzip**: `~> 2.3`

## Future Optimizations

### Parallel File Writing

**Opportunity**: Independent sections can be written concurrently

**Implementation**:
```ruby
require 'concurrent-ruby'

def write_multi_file_parallel(base_path, sections)
  futures = sections.map do |name, objects|
    Concurrent::Future.execute do
      chunk_and_write_section(name, objects)
    end
  end

  futures.each(&:wait)
end
```

**Benefit**: 3-5x speedup for large schemas with many sections

### Compression

**Opportunity**: Gzip individual files to reduce disk usage

**Trade-off**: CPU time vs disk space
- 500-line SQL file: ~20KB raw, ~3KB gzipped
- 200 files: 4MB raw, ~600KB gzipped

**Future config**:
```ruby
config.compress_files = true  # Write .sql.gz files
```

### Incremental Dumps

**Opportunity**: Only regenerate changed objects

**Requirements**:
- Track object fingerprints (hash of definition)
- Detect changes since last dump
- Only regenerate affected files

**Benefit**: 10-100x speedup for incremental changes

**Complexity**: High - requires change tracking database table
