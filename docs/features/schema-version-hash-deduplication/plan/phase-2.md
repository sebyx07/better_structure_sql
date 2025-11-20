# Phase 2: Hash Calculation and Comparison Logic

## Objective

Implement hash calculation for schema content and comparison logic in SchemaVersions module. Enable hash-based duplicate detection without yet integrating into storage flow.

## Deliverables

### 1. Hash Calculation Methods
**File**: `lib/better_structure_sql/schema_versions.rb`

- `calculate_hash(content)` - MD5 hexdigest of content string
- `calculate_hash_from_file(path)` - Read file and calculate hash
- `calculate_hash_from_directory(path)` - Read multi-file directory and calculate hash of combined content

### 2. Hash Query Methods
**File**: `lib/better_structure_sql/schema_versions.rb`

- `latest_hash(connection)` - Retrieve most recent version's content_hash
- `hash_exists?(hash, connection)` - Check if hash stored in any version
- `find_by_hash(hash, connection)` - Retrieve version by content_hash

### 3. Content Reading Helpers
**File**: `lib/better_structure_sql/schema_versions.rb`

- `read_and_hash_content(output_path, output_mode)` - Combined read + hash operation
- Ensure consistent hashing for single-file vs multi-file modes

### 4. Unit Tests
**File**: `spec/lib/better_structure_sql/schema_versions_spec.rb`

- Hash calculation tests for various content sizes
- Hash consistency tests (same content → same hash)
- Latest hash retrieval tests
- Hash existence check tests
- Single-file vs multi-file hash equality tests

## Testing Requirements

### Hash Calculation Tests
```ruby
RSpec.describe SchemaVersions do
  describe '.calculate_hash' do
    it 'returns 32-character MD5 hexdigest'
    it 'returns same hash for identical content'
    it 'returns different hash for different content'
    it 'handles empty string content'
    it 'handles large content (5MB+)'
    it 'handles UTF-8 content correctly'
  end

  describe '.calculate_hash_from_file' do
    it 'calculates hash from single file'
    it 'returns same hash as calculate_hash for same content'
    it 'raises error if file not found'
  end

  describe '.calculate_hash_from_directory' do
    it 'calculates hash from multi-file directory'
    it 'combines content in correct order (matches stored content)'
    it 'includes header and manifest comments'
    it 'returns same hash as single-file for equivalent content'
    it 'raises error if directory not found'
  end
end
```

### Hash Query Tests
```ruby
RSpec.describe SchemaVersions do
  describe '.latest_hash' do
    it 'returns hash of most recent version'
    it 'returns nil when no versions exist'
    it 'uses created_at DESC ordering'
  end

  describe '.hash_exists?' do
    it 'returns true when hash found'
    it 'returns false when hash not found'
    it 'returns false when no versions exist'
  end

  describe '.find_by_hash' do
    it 'finds version by content_hash'
    it 'returns nil when hash not found'
    it 'returns most recent version if multiple match'
  end
end
```

### Integration Tests
```ruby
RSpec.describe 'Hash calculation integration', type: :integration do
  it 'single-file and multi-file produce same hash for equivalent schema' do
    # 1. Dump schema as single file
    # 2. Calculate hash
    # 3. Dump schema as multi-file
    # 4. Calculate hash from combined content
    # 5. Verify hashes match
  end

  it 'hash changes when schema changes' do
    # 1. Dump schema, calculate hash
    # 2. Add table migration
    # 3. Dump schema again, calculate hash
    # 4. Verify hashes differ
  end

  it 'hash unchanged when only whitespace changes' do
    # 1. Dump schema, calculate hash
    # 2. Manually add extra blank lines
    # 3. Calculate hash again
    # 4. Verify hashes differ (hash is content-sensitive)
  end
end
```

## Success Criteria

1. ✅ `calculate_hash(content)` returns valid 32-char MD5 hexdigest
2. ✅ Hash calculation deterministic (same content → same hash)
3. ✅ Single-file and multi-file modes produce same hash for equivalent content
4. ✅ `latest_hash(connection)` queries most recent version correctly
5. ✅ `hash_exists?(hash)` performs fast indexed lookup
6. ✅ Hash calculation performance <10ms for schemas up to 500 tables
7. ✅ Test coverage >95% for hash calculation logic
8. ✅ Integration tests verify hash changes with schema changes
9. ✅ Error handling for missing files/directories
10. ✅ UTF-8 content handled correctly (no encoding issues)

## Dependencies

### Prerequisites
- Phase 1: `content_hash` column exists in database
- Phase 1: SchemaVersion model validates content_hash
- Existing SchemaVersions module operational

### Blocks
- None (isolated logic development)

### Enables
- Phase 3: Storage deduplication integration
- Phase 4: Rake task output enhancements

## Implementation Notes

### Hash Calculation Implementation
```ruby
module SchemaVersions
  def self.calculate_hash(content)
    require 'digest/md5'
    Digest::MD5.hexdigest(content)
  end

  def self.calculate_hash_from_file(path)
    content = File.read(path)
    calculate_hash(content)
  end

  def self.calculate_hash_from_directory(path)
    # Read multi-file content in same order as read_multi_file_content
    content = read_multi_file_content(path)
    calculate_hash(content)
  end
end
```

### Query Implementation
```ruby
module SchemaVersions
  def self.latest_hash(connection)
    SchemaVersion.latest.pluck(:content_hash).first
  end

  def self.hash_exists?(hash, connection)
    SchemaVersion.where(content_hash: hash).exists?
  end

  def self.find_by_hash(hash, connection)
    SchemaVersion.where(content_hash: hash).order(created_at: :desc).first
  end
end
```

### Combined Read + Hash
```ruby
module SchemaVersions
  def self.read_and_hash_content(output_path, output_mode)
    content, zip_archive, file_count = read_schema_content(output_path, output_mode)
    content_hash = calculate_hash(content)
    [content, content_hash, zip_archive, file_count]
  end
end
```

## Edge Cases

### Hash Calculation
- **Empty content**: Valid hash `d41d8cd98f00b204e9800998ecf8427e`
- **Nil content**: Raise ArgumentError (defensive programming)
- **Very large content** (100MB+): MD5 handles efficiently, no memory issues
- **Binary content**: MD5 works on bytes, no encoding issues

### Query Edge Cases
- **No versions exist**: `latest_hash` returns nil gracefully
- **Multiple versions with same hash**: `find_by_hash` returns most recent
- **Database connection errors**: Let ActiveRecord exceptions bubble up

### File Reading Edge Cases
- **File not found**: Raise informative error with path
- **Directory not found**: Raise informative error with path
- **Permission denied**: Let Ruby IOError bubble up
- **Symlinks**: Follow symlinks (File.read behavior)

## Performance Considerations

### Hash Calculation Benchmarks
```ruby
# Target performance (benchmarked on modern laptop)
Benchmark.measure do
  100.times { calculate_hash(50.kilobytes) }
end
# => ~100ms (1ms per hash)

Benchmark.measure do
  10.times { calculate_hash(5.megabytes) }
end
# => ~500ms (50ms per hash)
```

### Query Performance
- **latest_hash**: Single query with LIMIT 1, uses existing index on `created_at DESC`
- **hash_exists?**: Indexed lookup on `content_hash`, O(log n) with B-tree index
- **find_by_hash**: Indexed lookup + optional sort, very fast for small result sets

### Optimization: Memoization
```ruby
# Within store_current call, cache latest hash
def self.store_current(connection)
  @latest_hash ||= latest_hash(connection)
  # Use @latest_hash for comparison
end
```

## Rollback Plan

### Code Rollback
- Remove new methods from SchemaVersions module
- Update tests to remove hash calculation specs
- No database changes (Phase 1 migration remains)

### Compatibility
- Phase 1 `content_hash` column remains functional
- Can calculate hashes manually if needed
- No breaking changes to existing API

## Files Modified

- `lib/better_structure_sql/schema_versions.rb` (new methods)
- `spec/lib/better_structure_sql/schema_versions_spec.rb` (new tests)
- `spec/integration/hash_calculation_spec.rb` (new integration tests)

## Files Created

- `spec/lib/better_structure_sql/schema_versions/hash_calculation_spec.rb` (optional: organized spec)

## Estimated Complexity

**Low-Medium** - Hash calculation straightforward, but ensuring consistency across single/multi-file modes requires careful testing. Query methods simple.

## Performance Testing

### Benchmark Suite
```ruby
# spec/benchmarks/hash_calculation_benchmark.rb
require 'benchmark'

RSpec.describe 'Hash calculation performance' do
  it 'calculates hash for 100-table schema in <5ms' do
    content = generate_schema_content(100) # Helper method
    time = Benchmark.realtime { SchemaVersions.calculate_hash(content) }
    expect(time).to be < 0.005
  end

  it 'calculates hash for 500-table schema in <20ms' do
    content = generate_schema_content(500)
    time = Benchmark.realtime { SchemaVersions.calculate_hash(content) }
    expect(time).to be < 0.020
  end

  it 'calculates hash for multi-file directory in <50ms' do
    # Use existing multi-file integration test directory
    time = Benchmark.realtime { SchemaVersions.calculate_hash_from_directory(path) }
    expect(time).to be < 0.050
  end
end
```

## Documentation Updates

### Inline Documentation
- YARD comments for all public methods
- Examples showing hash calculation usage
- Performance characteristics documented

### README Updates
- None yet (Phase 4 will update user-facing docs)
