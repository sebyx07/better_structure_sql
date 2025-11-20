# Phase 3: Storage Deduplication Integration

## Objective

Integrate hash comparison into `store_current` flow to skip storage when schema content hasn't changed. Enable automatic deduplication without requiring manual intervention.

## Deliverables

### 1. Updated Rake Task (db:schema:store)
**File**: `lib/tasks/better_structure_sql.rake`

- Call SchemaVersions.store_current (schema already dumped by db:migrate)
- Handle StoreResult display (skip vs stored messages)
- No need to dump - schema files already on filesystem

### 2. Updated SchemaVersions.store_current Method
**File**: `lib/better_structure_sql/schema_versions.rb`

- Calculate hash before storage decision
- Compare with latest version's hash
- Skip storage if hash matches (return skip result, no filesystem cleanup)
- Proceed with storage if hash differs or no previous versions
- **NEW**: Cleanup filesystem directory after ZIP stored (multi-file only)
- Maintain existing retention cleanup logic

### 3. StoreResult Value Object
**File**: `lib/better_structure_sql/store_result.rb` (new file)

- Encapsulate storage operation result
- Attributes: `skipped`, `version`, `version_id`, `hash`, `total_count`
- Methods: `skipped?`, `stored?`
- Clean separation between storage logic and output formatting

### 4. Updated SchemaVersions.store Method
**File**: `lib/better_structure_sql/schema_versions.rb`

- Accept `content_hash` parameter (required)
- Include in SchemaVersion.create! attributes
- **NEW**: Accept `cleanup_filesystem` callback for directory removal
- Return created version

### 5. Filesystem Cleanup Logic
**File**: `lib/better_structure_sql/schema_versions.rb`

- After successful ZIP storage, delete multi-file directory
- Only cleanup if multi-file mode and ZIP successfully stored
- Use `FileUtils.rm_rf(output_path)` for directory removal
- Skip cleanup if single-file mode or storage skipped

### 6. Integration Tests
**File**: `spec/integration/schema_version_deduplication_spec.rb`

- Full deduplication workflow tests
- Production scenario testing (repeated dumps without changes)
- Schema evolution tracking
- **NEW**: Directory cleanup verification tests

## Testing Requirements

### Deduplication Flow Tests
```ruby
RSpec.describe 'Schema version deduplication', type: :integration do
  describe 'duplicate detection' do
    it 'stores first version when no previous versions exist' do
      result = SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version).to be_persisted
      expect(result.version.content_hash).to be_present
      expect(SchemaVersion.count).to eq(1)
    end

    it 'skips storage when hash matches latest version' do
      # Store initial version
      SchemaVersions.store_current(connection)

      # Attempt to store again without schema changes
      result = SchemaVersions.store_current(connection)

      expect(result.skipped?).to be true
      expect(result.version_id).to eq(SchemaVersion.latest.id)
      expect(SchemaVersion.count).to eq(1)  # Still only one version
    end

    it 'stores new version when hash differs' do
      # Store initial version
      initial = SchemaVersions.store_current(connection)

      # Make schema change
      connection.execute('CREATE TABLE test_table (id INTEGER);')

      # Dump and store again
      Dumper.new(config).dump
      result = SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.content_hash).not_to eq(initial.version.content_hash)
      expect(SchemaVersion.count).to eq(2)
    end
  end

  describe 'multi-file mode deduplication' do
    before do
      config.output_path = Rails.root.join('db/schema')  # Directory mode
    end

    it 'detects duplicates in multi-file mode' do
      # Store initial version
      Dumper.new(config).dump
      SchemaVersions.store_current(connection)

      # Dump again without changes
      Dumper.new(config).dump
      result = SchemaVersions.store_current(connection)

      expect(result.skipped?).to be true
      expect(SchemaVersion.count).to eq(1)
    end

    it 'detects changes in multi-file mode' do
      # Store initial version
      Dumper.new(config).dump
      initial = SchemaVersions.store_current(connection)

      # Add table
      connection.execute('CREATE TABLE test_table (id INTEGER);')

      # Dump and store
      Dumper.new(config).dump
      result = SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.content_hash).not_to eq(initial.version.content_hash)
    end
  end

  describe 'production workflow simulation' do
    it 'handles repeated deploys without schema changes' do
      # Initial deploy with migrations
      connection.execute('CREATE TABLE users (id INTEGER);')
      Dumper.new(config).dump
      result1 = SchemaVersions.store_current(connection)
      expect(result1.stored?).to be true

      # Deploy 2: No migrations, no changes
      Dumper.new(config).dump
      result2 = SchemaVersions.store_current(connection)
      expect(result2.skipped?).to be true

      # Deploy 3: No migrations, no changes
      Dumper.new(config).dump
      result3 = SchemaVersions.store_current(connection)
      expect(result3.skipped?).to be true

      # Only 1 version stored
      expect(SchemaVersion.count).to eq(1)
    end

    it 'tracks actual schema evolution across deploys' do
      versions = []

      # Deploy 1: Initial schema
      connection.execute('CREATE TABLE users (id INTEGER);')
      Dumper.new(config).dump
      versions << SchemaVersions.store_current(connection)

      # Deploy 2: No changes (skipped)
      Dumper.new(config).dump
      SchemaVersions.store_current(connection)

      # Deploy 3: Add posts table
      connection.execute('CREATE TABLE posts (id INTEGER);')
      Dumper.new(config).dump
      versions << SchemaVersions.store_current(connection)

      # Deploy 4: No changes (skipped)
      Dumper.new(config).dump
      SchemaVersions.store_current(connection)

      # Deploy 5: Add comments table
      connection.execute('CREATE TABLE comments (id INTEGER);')
      Dumper.new(config).dump
      versions << SchemaVersions.store_current(connection)

      # Only 3 versions stored (deploys with actual changes)
      expect(SchemaVersion.count).to eq(3)
      expect(versions.select(&:stored?).count).to eq(3)

      # Each stored version has different hash
      hashes = versions.map { |v| v.version.content_hash }
      expect(hashes.uniq.count).to eq(3)
    end
  end

  describe 'filesystem cleanup' do
    before do
      config.output_path = Rails.root.join('db/schema')  # Multi-file mode
    end

    it 'deletes directory after storing ZIP archive' do
      # Dump creates directory
      Dumper.new(config).dump
      expect(Dir.exist?(config.output_path)).to be true

      # Store creates ZIP and deletes directory
      result = SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(result.version.zip_archive).to be_present
      expect(Dir.exist?(config.output_path)).to be false  # Directory deleted
    end

    it 'does not delete directory when storage skipped' do
      # First store (directory deleted after ZIP created)
      Dumper.new(config).dump
      SchemaVersions.store_current(connection)
      expect(Dir.exist?(config.output_path)).to be false

      # Dump again
      Dumper.new(config).dump
      expect(Dir.exist?(config.output_path)).to be true

      # Second store skipped (directory remains for re-use)
      result = SchemaVersions.store_current(connection)
      expect(result.skipped?).to be true
      expect(Dir.exist?(config.output_path)).to be true  # Directory NOT deleted
    end

    it 'does not delete single file after storing' do
      config.output_path = Rails.root.join('db/structure.sql')

      # Dump creates file
      Dumper.new(config).dump
      expect(File.exist?(config.output_path)).to be true

      # Store version (single-file, no ZIP)
      result = SchemaVersions.store_current(connection)

      expect(result.stored?).to be true
      expect(File.exist?(config.output_path)).to be true  # File NOT deleted
    end

    it 'handles cleanup errors gracefully' do
      # Store with valid directory
      Dumper.new(config).dump

      # Stub FileUtils.rm_rf to raise error
      allow(FileUtils).to receive(:rm_rf).and_raise(Errno::EACCES, 'Permission denied')

      # Storage should succeed despite cleanup failure
      expect {
        result = SchemaVersions.store_current(connection)
        expect(result.stored?).to be true
      }.to output(/Warning: Failed to cleanup directory/).to_stdout
    end
  end

  describe 'retention with deduplication' do
    before do
      config.schema_versions_limit = 3
    end

    it 'retains only unique versions within limit' do
      # Store 5 unique versions
      5.times do |i|
        connection.execute("CREATE TABLE table_#{i} (id INTEGER);")
        Dumper.new(config).dump
        SchemaVersions.store_current(connection)
      end

      # Only 3 most recent retained
      expect(SchemaVersion.count).to eq(3)

      # All have different hashes
      hashes = SchemaVersion.pluck(:content_hash)
      expect(hashes.uniq.count).to eq(3)
    end

    it 'does not count skipped attempts toward retention limit' do
      config.schema_versions_limit = 2

      # Store 3 unique versions
      connection.execute("CREATE TABLE table_1 (id INTEGER);")
      Dumper.new(config).dump
      v1 = SchemaVersions.store_current(connection)

      connection.execute("CREATE TABLE table_2 (id INTEGER);")
      Dumper.new(config).dump
      v2 = SchemaVersions.store_current(connection)

      connection.execute("CREATE TABLE table_3 (id INTEGER);")
      Dumper.new(config).dump
      v3 = SchemaVersions.store_current(connection)

      # Oldest version (v1) deleted by retention
      expect(SchemaVersion.count).to eq(2)
      expect(SchemaVersion.pluck(:id)).to contain_exactly(v2.version.id, v3.version.id)

      # Attempt to store duplicate of v3 (skipped, no cleanup)
      Dumper.new(config).dump
      result = SchemaVersions.store_current(connection)
      expect(result.skipped?).to be true

      # Still only 2 versions
      expect(SchemaVersion.count).to eq(2)
    end
  end
end
```

### StoreResult Tests
```ruby
RSpec.describe StoreResult do
  describe '#skipped?' do
    it 'returns true when skipped' do
      result = StoreResult.new(skipped: true, version_id: 5, hash: 'abc123')
      expect(result.skipped?).to be true
      expect(result.stored?).to be false
    end
  end

  describe '#stored?' do
    it 'returns true when stored' do
      version = create(:schema_version)
      result = StoreResult.new(skipped: false, version: version)
      expect(result.stored?).to be true
      expect(result.skipped?).to be false
    end
  end

  describe 'attributes' do
    it 'provides version_id for skipped result' do
      result = StoreResult.new(skipped: true, version_id: 10, hash: 'def456')
      expect(result.version_id).to eq(10)
      expect(result.hash).to eq('def456')
    end

    it 'provides version for stored result' do
      version = create(:schema_version)
      result = StoreResult.new(skipped: false, version: version)
      expect(result.version).to eq(version)
      expect(result.version_id).to eq(version.id)
    end
  end
end
```

## Success Criteria

1. ✅ `store_current` calculates hash before storage
2. ✅ `store_current` compares hash with latest version
3. ✅ Storage skipped when hash matches
4. ✅ Storage proceeds when hash differs
5. ✅ Storage proceeds when no previous versions exist
6. ✅ StoreResult encapsulates skip/store states cleanly
7. ✅ Retention cleanup only runs on actual storage (not skips)
8. ✅ Test coverage >95% for deduplication logic
9. ✅ Production workflow tests pass (repeated deploys)
10. ✅ Multi-file and single-file modes both deduplicate correctly

## Dependencies

### Prerequisites
- Phase 1: `content_hash` column and model validations
- Phase 2: Hash calculation and comparison methods
- Existing storage and cleanup logic operational

### Blocks
- None (core feature implementation)

### Enables
- Phase 4: Rake task output enhancements
- Production deployment with deduplication

## Implementation Notes

### StoreResult Value Object
```ruby
# lib/better_structure_sql/store_result.rb
module BetterStructureSql
  class StoreResult
    attr_reader :version, :version_id, :hash, :total_count

    def initialize(skipped:, version: nil, version_id: nil, hash: nil, total_count: nil)
      @skipped = skipped
      @version = version
      @version_id = version_id || version&.id
      @hash = hash || version&.content_hash
      @total_count = total_count
    end

    def skipped?
      @skipped
    end

    def stored?
      !@skipped
    end
  end
end
```

### Updated store_current Method
```ruby
def self.store_current(connection)
  # Detect format, mode, read content
  output_path = config.output_path
  format_type = deduce_format_type(output_path)
  output_mode = detect_output_mode(output_path)
  pg_version = DatabaseVersion.detect(connection)

  # Read content and calculate hash
  content, zip_archive, file_count = read_schema_content(output_path, output_mode)
  return build_skip_result(nil, SchemaVersion.count) unless content

  content_hash = calculate_hash(content)

  # Compare with latest version's hash
  latest_version = SchemaVersion.latest
  if latest_version && latest_version.content_hash == content_hash
    # Skip storage - no changes detected (directory remains for re-use)
    return build_skip_result(latest_version, SchemaVersion.count)
  end

  # Proceed with storage - hash differs or no previous versions
  version = store(
    content: content,
    content_hash: content_hash,
    format_type: format_type,
    pg_version: pg_version,
    output_mode: output_mode,
    zip_archive: zip_archive,
    file_count: file_count,
    connection: connection
  )

  # **NEW: Cleanup filesystem directory after ZIP stored**
  cleanup_filesystem_directory(output_path, output_mode)

  # Cleanup old versions (retention management)
  cleanup!(connection)

  # Return stored result
  build_stored_result(version)
end

private

def self.cleanup_filesystem_directory(output_path, output_mode)
  # Only cleanup multi-file directories (single files remain)
  return unless output_mode == 'multi_file'
  return unless Dir.exist?(output_path)

  FileUtils.rm_rf(output_path)
rescue StandardError => e
  warn "Warning: Failed to cleanup directory #{output_path}: #{e.message}"
  # Continue despite cleanup failure - version already stored
end

private

def self.build_skip_result(version, total_count)
  StoreResult.new(
    skipped: true,
    version_id: version&.id,
    hash: version&.content_hash,
    total_count: total_count
  )
end

def self.build_stored_result(version)
  StoreResult.new(
    skipped: false,
    version: version,
    total_count: SchemaVersion.count
  )
end
```

### Updated store Method
```ruby
def self.store(content:, content_hash:, format_type:, pg_version:, **options)
  connection = options[:connection] || ActiveRecord::Base.connection
  output_mode = options[:output_mode] || 'single_file'
  zip_archive = options[:zip_archive]
  file_count = options[:file_count]

  SchemaVersion.create!(
    content: content,
    content_hash: content_hash,
    format_type: format_type,
    pg_version: pg_version,
    output_mode: output_mode,
    zip_archive: zip_archive,
    file_count: file_count
  )
end
```

## Edge Cases

### No Previous Versions
- **First storage**: No latest_version, comparison skipped, storage proceeds
- **Empty database**: Valid scenario, creates first version

### Latest Version Query Failure
- **Database error**: Let ActiveRecord exception bubble up
- **Null result**: Handled gracefully (`latest_version` is nil)

### Hash Calculation Failure
- **File not found**: Raise error (schema should exist after dump)
- **Empty content**: Valid hash, comparison proceeds

### Concurrent Storage
- **Race condition**: Two processes storing simultaneously
- **Impact**: Both may store (hash comparison not transactional)
- **Mitigation**: Not critical (minor duplication acceptable in rare case)
- **Future enhancement**: Database-level uniqueness constraint on content_hash

### Retention Interaction
- **Skip doesn't trigger cleanup**: Cleanup only runs after successful storage
- **Retention limit reached**: Cleanup removes oldest unique versions
- **Duplicate older than limit**: Already removed by previous cleanup

## Performance Considerations

### Additional Overhead
- **Hash calculation**: ~5ms for typical schema (Phase 2 benchmarks)
- **Latest version query**: ~1ms (single indexed query)
- **Hash comparison**: <1ms (string equality)
- **Total overhead**: ~6ms per store attempt

### Skip Path Performance
- **No database write**: Saves INSERT operation (~10ms)
- **No cleanup**: Saves DELETE queries
- **Net benefit**: Skip path faster than full storage

### Storage Path Performance
- **Unchanged**: Same as current implementation plus hash calculation (~5ms)

## Rollback Plan

### Code Rollback
- Revert `store_current` to always store (remove hash comparison)
- Remove StoreResult class (return version directly)
- Update tests to expect always-stored behavior

### Data Impact
- No data loss (existing versions remain)
- Future stores create duplicates (back to old behavior)

### Gradual Rollback
```ruby
# Temporary feature flag in configuration
config.enable_hash_deduplication = false  # Default true

# In store_current:
if config.enable_hash_deduplication
  # Compare hash, skip if match
else
  # Always store (old behavior)
end
```

## Files Modified

- `lib/better_structure_sql/schema_versions.rb` (updated store_current and store)
- `lib/better_structure_sql/store_result.rb` (new file)
- `spec/integration/schema_version_deduplication_spec.rb` (new file)
- `spec/lib/better_structure_sql/store_result_spec.rb` (new file)

## Files Created

- `lib/better_structure_sql/store_result.rb`
- `spec/integration/schema_version_deduplication_spec.rb`
- `spec/lib/better_structure_sql/store_result_spec.rb`

## Estimated Complexity

**Medium** - Core deduplication logic straightforward, but StoreResult abstraction and comprehensive testing add complexity. Production workflow simulation tests critical.

## Production Considerations

### Deployment Workflow Integration
```ruby
# After migrations in production deploy
namespace :deploy do
  task :update_schema do
    # 1. Run migrations (if any)
    Rake::Task['db:migrate'].invoke

    # 2. Dump schema (always)
    Rake::Task['db:schema:dump_better'].invoke

    # 3. Store version (only if changed)
    Rake::Task['db:schema:store'].invoke
    # => Will skip if no schema changes from previous deploy
  end
end
```

### Benefits in Production
- **No duplicate storage**: Deploys without migrations don't create versions
- **Clear audit trail**: Only actual schema changes tracked
- **Storage efficiency**: Database table stays small
- **Developer experience**: Schema version list shows meaningful changes
- **Web UI clarity**: Developers see evolution, not deployment noise

### Monitoring
- Log skip vs store decisions for visibility
- Track skip rate (expected high in stable production)
- Alert on unexpected storage patterns

## Documentation Updates

### Inline Documentation
- YARD comments for store_current explaining deduplication
- StoreResult class documentation with examples
- Update existing store method docs to mention content_hash parameter
