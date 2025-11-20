# Phase 4: Rake Task Output and Documentation

## Objective

Update rake task output to show deduplication decisions and hash information. Update user-facing documentation with examples and usage patterns. Complete feature with polished UX.

## Deliverables

### 1. Enhanced Rake Task Output
**File**: `lib/tasks/better_structure_sql.rake`

- Update `db:schema:store` to display StoreResult appropriately
- Show skip message with reason and matching version
- Show stored message with hash and metadata
- Update `db:schema:versions` to display content_hash column

### 2. README Updates
**File**: `README.md`

- Document hash-based deduplication feature
- Show examples of skip vs store output
- Explain production workflow benefits
- Add configuration section (if any future config added)

### 3. Feature Documentation
**File**: `docs/features/schema-version-hash-deduplication/README.md`

- Already created, review and finalize
- Ensure examples match actual output
- Add troubleshooting section

### 4. CLAUDE.md Updates
**File**: `CLAUDE.md`

- Add minimal keyword-rich context about deduplication
- Document hash calculation approach
- Note production deployment use case

### 5. Changelog Entry
**File**: `CHANGELOG.md`

- Document new feature in appropriate version section
- Breaking changes: content_hash column required
- Migration instructions

## Testing Requirements

### Rake Task Output Tests
```ruby
RSpec.describe 'db:schema:store rake task', type: :task do
  describe 'skip output' do
    it 'displays skip message when hash matches' do
      # Store initial version
      Rake::Task['db:schema:store'].invoke
      Rake::Task['db:schema:store'].reenable

      # Store again (should skip)
      output = capture_stdout do
        Rake::Task['db:schema:store'].invoke
      end

      expect(output).to include('No schema changes detected')
      expect(output).to include('matches version #')
      expect(output).to include('hash:')
      expect(output).to include('No new version stored')
      expect(output).to include('Total versions:')
    end
  end

  describe 'stored output' do
    it 'displays stored message with hash' do
      output = capture_stdout do
        Rake::Task['db:schema:store'].invoke
      end

      expect(output).to include('Stored schema version')
      expect(output).to include('Format: sql')
      expect(output).to include('Mode: single_file')
      expect(output).to include('Hash:')
      expect(output).to match(/Hash: [a-f0-9]{32}/)
      expect(output).to include('Total versions:')
    end
  end
end

RSpec.describe 'db:schema:versions rake task', type: :task do
  it 'displays content_hash column' do
    create_list(:schema_version, 3)

    output = capture_stdout do
      Rake::Task['db:schema:versions'].invoke
    end

    expect(output).to include('Hash')
    expect(output).to match(/[a-f0-9]{8}/)  # First 8 chars displayed
  end

  it 'truncates long hashes for table display' do
    version = create(:schema_version, content_hash: 'a' * 32)

    output = capture_stdout do
      Rake::Task['db:schema:versions'].invoke
    end

    expect(output).to include('aaaaaaaa')  # First 8 only
    expect(output).not_to include('a' * 32)  # Full hash not shown
  end
end
```

### Documentation Tests (Manual)
- Verify README examples accurate
- Confirm code samples work as shown
- Check links and formatting
- Ensure migration instructions complete

## Success Criteria

1. ✅ `db:schema:store` displays informative skip message
2. ✅ `db:schema:store` shows hash in stored message
3. ✅ `db:schema:versions` includes Hash column (first 8 chars)
4. ✅ README documents deduplication feature with examples
5. ✅ CLAUDE.md updated with deduplication keywords
6. ✅ CHANGELOG.md documents feature and migration
7. ✅ Feature documentation finalized and accurate
8. ✅ All documentation examples verified working
9. ✅ Test coverage >95% for rake task output
10. ✅ User-facing documentation clear and complete

## Dependencies

### Prerequisites
- Phase 3: StoreResult implementation and deduplication logic
- All previous phases: Database, model, hash calculation

### Blocks
- None (final phase)

### Enables
- Feature complete and ready for production use
- User adoption with clear documentation

## Implementation Notes

### Enhanced db:schema:store Task
```ruby
namespace :db do
  namespace :schema do
    desc 'Store current schema as version'
    task store: :environment do
      config = BetterStructureSql.configuration
      unless config.enable_schema_versions
        puts 'Schema versioning is disabled. Enable in config/initializers/better_structure_sql.rb'
        next
      end

      connection = ActiveRecord::Base.connection
      result = BetterStructureSql::SchemaVersions.store_current(connection)

      if result.skipped?
        puts "\nNo schema changes detected"
        puts "  Current schema matches version ##{result.version_id}"
        puts "  Hash: #{result.hash}"
        puts "  No new version stored"
        puts "  Total versions: #{result.total_count}"
      else
        version = result.version
        puts "\nStored schema version ##{version.id}"
        puts "  Format: #{version.format_type}"
        puts "  Mode: #{version.output_mode}"
        puts "  Files: #{version.file_count || '-'}" if version.multi_file?
        puts "  PostgreSQL: #{version.pg_version}"
        puts "  Size: #{version.formatted_size}"
        puts "  Hash: #{version.content_hash}"
        puts "  Total versions: #{result.total_count}"
      end
    rescue StandardError => e
      puts "\nError storing schema version: #{e.message}"
      puts e.backtrace.first(5).join("\n") if ENV['VERBOSE']
      exit 1
    end
  end
end
```

### Enhanced db:schema:versions Task
```ruby
namespace :db do
  namespace :schema do
    desc 'List stored schema versions'
    task versions: :environment do
      versions = BetterStructureSql::SchemaVersion.order(created_at: :desc)

      if versions.empty?
        puts 'No schema versions stored yet'
        next
      end

      # Table header
      puts "\n%-4s | %-6s | %-11s | %-5s | %-10s | %-10s | %-19s | %-8s" %
        ['ID', 'Format', 'Mode', 'Files', 'PostgreSQL', 'Hash', 'Created', 'Size']
      puts '-' * 90

      # Table rows
      versions.each do |version|
        puts "%-4d | %-6s | %-11s | %-5s | %-10s | %-10s | %-19s | %-8s" % [
          version.id,
          version.format_type,
          version.output_mode,
          version.file_count || '-',
          version.pg_version,
          version.content_hash[0..7],  # First 8 characters
          version.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          version.formatted_size
        ]
      end

      puts "\nTotal versions: #{versions.count}"
    end
  end
end
```

### README Section Addition
```markdown
## Schema Versioning with Deduplication

BetterStructureSql automatically tracks schema evolution by storing versions in your database. Hash-based deduplication ensures only meaningful schema changes are recorded.

### How It Works

When you run `rails db:schema:store`, the gem:
1. Reads your current schema files (single or multi-file)
2. Calculates MD5 hash of the complete schema content
3. Compares with the most recent stored version's hash
4. **Skips storage** if hash matches (no changes)
5. **Creates new version** if hash differs (schema changed)

### Usage

```bash
# After migrations, dump and store schema
rails db:migrate
rails db:schema:dump_better
rails db:schema:store

# First run (no previous version)
# => Stored schema version #1
#    Hash: a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4
#    Total versions: 1

# Second run (no schema changes)
# => No schema changes detected
#    Current schema matches version #1
#    No new version stored
#    Total versions: 1

# After making changes
rails db:migrate  # Adds new table
rails db:schema:dump_better
rails db:schema:store

# => Stored schema version #2
#    Hash: b7e2d1c4f9a6c3e5d8b2f1a4c9e7d3b6
#    Total versions: 2
```

### Production Workflow

```ruby
# config/deploy.rb or similar
namespace :deploy do
  task :update_schema do
    on roles(:app) do
      within release_path do
        # Run migrations (may be zero)
        execute :rake, 'db:migrate'

        # Always dump latest schema
        execute :rake, 'db:schema:dump_better'

        # Store only if changed (automatic deduplication)
        execute :rake, 'db:schema:store'
      end
    end
  end
end
```

**Benefits in Production**:
- Deploys without migrations don't create duplicate versions
- Developers see clean schema evolution timeline via Web UI
- Storage efficient (no duplicate content)
- Clear audit trail of actual schema changes

### Viewing Stored Versions

```bash
# List all versions with hashes
rails db:schema:versions

ID  | Format | Mode        | Files | PostgreSQL | Hash       | Created             | Size
----|--------|-------------|-------|------------|------------|---------------------|-------
15  | sql    | multi_file  | 47    | 15.4       | a3f5c9d2   | 2025-01-18 10:45:22 | 125 KB
14  | sql    | multi_file  | 45    | 15.4       | b7e2d1c4   | 2025-01-17 15:30:10 | 118 KB
13  | sql    | single_file | -     | 15.3       | c9f8a3b2   | 2025-01-15 09:20:05 | 98 KB
```

### Configuration

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  # Enable schema versioning
  config.enable_schema_versions = true

  # Retain 10 most recent unique versions (0 = unlimited)
  config.schema_versions_limit = 10
end
```

### Developer Access

Developers can view stored schema versions via the web UI without database access:

```ruby
# config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end
```

Navigate to `/schema_versions` to browse stored versions, view formatted schema, and download raw SQL files.
```

### CLAUDE.md Addition
```markdown
## Schema Version Hash Deduplication

MD5 hash-based duplicate detection for schema version storage. Prevents storing identical versions when schema unchanged between deploys. Hash calculated on combined content (single-file or multi-file combined). Comparison with latest stored version hash before INSERT. Skip storage if hash match, proceed if different or no previous versions. Production deployment workflow: migrate → dump → store (auto-deduplicates). Developer access via Web UI shows only unique schema evolution events. Storage efficiency, clear audit trail, reduced noise. content_hash column VARCHAR(32) indexed. StoreResult value object encapsulates skip/store decisions. Rake task output shows skip reason and matching version or stored confirmation with hash. Hash calculation ~5ms overhead, query ~1ms, comparison negligible. No duplicate versions in production environment. Integration with retention management (cleanup only on actual storage). Multi-database adapter support (PostgreSQL, MySQL, SQLite all support VARCHAR/TEXT hash column).
```

## Edge Cases

### Task Error Handling
- **Configuration disabled**: Show helpful message, don't error
- **Database connection failure**: Catch and display friendly error
- **File read failure**: Propagate error with context
- **StoreResult nil**: Defensive handling with fallback message

### Output Formatting
- **Very long hashes**: Truncate in list view (first 8 chars)
- **Missing version metadata**: Display '-' for null fields
- **Unicode in error messages**: Ensure proper encoding

## User Experience Improvements

### Informative Messages
- **Skip**: Explain why (hash matches) and which version
- **Store**: Confirm with full metadata including hash
- **Error**: Actionable error messages with troubleshooting hints

### Visual Clarity
```
# Good skip message (informative)
No schema changes detected
  Current schema matches version #42 (created 2 hours ago)
  Hash: a3f5c9d2e8b1f4a6c7e9d3f1b5a8c2e4
  No new version stored
  Total versions: 15

# Good store message (complete metadata)
Stored schema version #43
  Format: sql
  Mode: multi_file
  Files: 47
  PostgreSQL: 15.4
  Size: 125.3 KB
  Hash: b7e2d1c4f9a6c3e5d8b2f1a4c9e7d3b6
  Total versions: 16
```

### Table Formatting
```
# Clean aligned columns
ID  | Format | Mode        | Files | PostgreSQL | Hash       | Created             | Size
----|--------|-------------|-------|------------|------------|---------------------|-------
15  | sql    | multi_file  | 47    | 15.4       | a3f5c9d2   | 2025-01-18 10:45:22 | 125 KB
14  | sql    | multi_file  | 45    | 15.4       | b7e2d1c4   | 2025-01-17 15:30:10 | 118 KB
```

## Documentation Quality Checklist

### README
- [ ] Feature overview clear and concise
- [ ] Examples show actual command output
- [ ] Production workflow documented
- [ ] Benefits explained (why use this)
- [ ] Web UI integration mentioned

### CLAUDE.md
- [ ] Keyword-rich (no code samples)
- [ ] Concepts and integration points covered
- [ ] Multi-database support noted
- [ ] Performance characteristics mentioned

### CHANGELOG.md
- [ ] Feature announcement with version
- [ ] Breaking change: migration required
- [ ] Migration instructions included
- [ ] Benefits highlighted

### Feature Docs
- [ ] README accurate and complete
- [ ] Architecture document technical details
- [ ] Phase plans executable
- [ ] Examples verified working

## Files Modified

- `lib/tasks/better_structure_sql.rake` (enhanced output)
- `README.md` (new section on deduplication)
- `CLAUDE.md` (deduplication keywords)
- `CHANGELOG.md` (feature announcement)
- `docs/features/schema-version-hash-deduplication/README.md` (review/finalize)

## Files Created

- None (documentation phase)

## Estimated Complexity

**Low** - Mostly documentation and polish. Rake task output straightforward formatting.

## Final Testing

### Manual Testing Checklist
- [ ] Run `db:schema:store` first time, verify stored message
- [ ] Run `db:schema:store` again, verify skip message
- [ ] Make schema change, verify stored message with different hash
- [ ] Run `db:schema:versions`, verify hash column displayed
- [ ] Test with multi-file mode
- [ ] Test with single-file mode
- [ ] Verify all README examples work as shown
- [ ] Check output formatting on narrow terminal (80 cols)
- [ ] Check output with very long database names
- [ ] Verify error messages actionable

### Integration Testing
- [ ] Full production workflow simulation
- [ ] Repeated deploys without changes (all skip)
- [ ] Deploys with changes (store)
- [ ] Retention management with deduplication
- [ ] Multi-database adapter testing (PostgreSQL, MySQL, SQLite)

## Success Metrics

### User Experience
- Users understand why storage skipped
- Hash value visible for verification
- Output messages informative and concise
- Error messages actionable

### Documentation Quality
- README examples copy-paste-runnable
- Production workflow clear
- Benefits articulated
- Troubleshooting guidance provided

### Feature Completeness
- All phases implemented
- All tests passing (>95% coverage)
- Documentation complete
- Ready for production deployment
