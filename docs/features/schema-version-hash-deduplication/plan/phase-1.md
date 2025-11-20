# Phase 1: Database Schema and Model Changes

## Objective

Add `content_hash` column to schema versions table and update SchemaVersion model with hash validation. Establish database foundation for deduplication feature.

## Deliverables

### 1. Database Migration
**File**: `db/migrate/YYYYMMDDHHMMSS_add_content_hash_to_schema_versions.rb`

- Add `content_hash` column (VARCHAR 32, NOT NULL)
- Create index on `content_hash` column
- Backfill existing records with calculated hashes
- Support PostgreSQL, MySQL, SQLite adapters

### 2. Integration App Migrations
**Files**:
- `integration/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (PostgreSQL)
- `integration_mysql/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (MySQL)
- `integration_sqlite/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (SQLite)

### 3. SchemaVersion Model Updates
**File**: `lib/better_structure_sql/schema_version.rb`

- Add `content_hash` attribute
- Validate presence: `validates :content_hash, presence: true`
- Validate format: `validates :content_hash, format: { with: /\A[a-f0-9]{32}\z/ }`
- Add `hash_matches?(other_hash)` comparison method
- Update factory/fixtures with content_hash

### 4. Model Tests
**File**: `spec/models/schema_version_spec.rb`

- Test `content_hash` presence validation
- Test `content_hash` format validation (32 hex chars)
- Test `hash_matches?(hash)` comparison
- Test invalid formats (31 chars, 33 chars, non-hex)
- Test factory creates valid content_hash

## Testing Requirements

### Migration Tests
- Migration runs successfully (up and down)
- Column created with correct type and constraints
- Index created on content_hash column
- Backfill calculates correct MD5 hashes for existing records
- Migration reversible (rollback works)
- All three adapters (PostgreSQL, MySQL, SQLite) supported

### Model Validation Tests
```ruby
RSpec.describe SchemaVersion, type: :model do
  describe 'validations' do
    it 'validates presence of content_hash'
    it 'validates content_hash format (32 hex characters)'
    it 'rejects content_hash with 31 characters'
    it 'rejects content_hash with 33 characters'
    it 'rejects content_hash with non-hex characters (g, z, etc.)'
    it 'accepts valid MD5 hash'
  end

  describe '#hash_matches?' do
    it 'returns true when hashes match'
    it 'returns false when hashes differ'
    it 'handles nil comparison'
  end
end
```

### Database Compatibility Tests
- PostgreSQL: VARCHAR(32) column created
- MySQL: VARCHAR(32) with utf8mb4 collation
- SQLite: TEXT column (no length limit)
- All adapters: Index created and usable

## Success Criteria

1. ✅ Migration adds `content_hash VARCHAR(32) NOT NULL` column
2. ✅ Index created on `content_hash` column
3. ✅ Backfill populates existing records with MD5 hashes
4. ✅ SchemaVersion model validates presence and format
5. ✅ `hash_matches?(hash)` method compares correctly
6. ✅ All three database adapters supported
7. ✅ Migration reversible without errors
8. ✅ Test coverage >95% for model validations
9. ✅ Factory creates valid records with content_hash
10. ✅ No regressions in existing schema version functionality

## Dependencies

### Prerequisites
- Existing schema_versions table structure
- SchemaVersion model operational
- Migration infrastructure in place

### Blocks
- None (foundation phase)

### Enables
- Phase 2: Hash calculation and comparison logic
- Phase 3: Storage deduplication

## Implementation Notes

### Migration Structure
```ruby
class AddContentHashToSchemaVersions < ActiveRecord::Migration[7.0]
  def change
    add_column :better_structure_sql_schema_versions, :content_hash, :string, limit: 32
    add_index :better_structure_sql_schema_versions, :content_hash

    reversible do |dir|
      dir.up do
        # Backfill existing records
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

### Model Validation
```ruby
class SchemaVersion < ActiveRecord::Base
  validates :content_hash, presence: true,
                           format: { with: /\A[a-f0-9]{32}\z/,
                                     message: 'must be 32-character MD5 hex digest' }

  def hash_matches?(other_hash)
    content_hash == other_hash
  end
end
```

### Factory Updates
```ruby
# spec/factories/schema_versions.rb
FactoryBot.define do
  factory :schema_version, class: 'BetterStructureSql::SchemaVersion' do
    content { "CREATE TABLE users (id INTEGER);" }
    content_hash { Digest::MD5.hexdigest(content) }
    format_type { 'sql' }
    output_mode { 'single_file' }
    pg_version { '15.4' }
  end
end
```

## Edge Cases

- **Empty content**: Hash of empty string valid (`d41d8cd98f00b204e9800998ecf8427e`)
- **NULL content**: Model validation prevents NULL content, hash calculation fails gracefully
- **Existing records without content_hash**: Backfill handles during migration
- **Large content**: MD5 fast even for multi-MB schemas
- **Unicode content**: MD5 handles UTF-8 correctly (bytes, not characters)

## Rollback Plan

### Undo Migration
```ruby
def down
  remove_index :better_structure_sql_schema_versions, :content_hash
  remove_column :better_structure_sql_schema_versions, :content_hash
end
```

### Model Rollback
- Remove validations
- Remove `hash_matches?` method
- Update factories to not include content_hash

## Files Modified

- `lib/better_structure_sql/schema_version.rb` (model updates)
- `db/migrate/YYYYMMDDHHMMSS_add_content_hash_to_schema_versions.rb` (new migration)
- `integration/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (PostgreSQL integration)
- `integration_mysql/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (MySQL integration)
- `integration_sqlite/db/migrate/YYYYMMDDHHMMSS_add_content_hash.rb` (SQLite integration)
- `spec/models/schema_version_spec.rb` (new or updated tests)
- `spec/factories/schema_versions.rb` (factory updates)

## Estimated Complexity

**Low** - Straightforward migration and model validation. No complex logic or external dependencies.
