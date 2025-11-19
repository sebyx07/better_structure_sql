# Phase 3: SQLite Adapter Implementation

## Objective

Implement SQLite adapter with sqlite_master introspection and SQLite SQL dialect generation. Create SQLite integration app for testing lightweight database support.

## Deliverables

### 1. SQLite Adapter Core Implementation
**Files**:
- `lib/better_structure_sql/adapters/sqlite_adapter.rb`
- `lib/better_structure_sql/adapters/sqlite_config.rb`

**Tasks**:
- Implement SqliteAdapter inheriting from BaseAdapter
- Implement fetch_tables using sqlite_master
- Implement fetch_indexes using PRAGMA index_list + PRAGMA index_info
- Implement fetch_foreign_keys using PRAGMA foreign_key_list
- Implement fetch_views using sqlite_master (type='view')
- Implement fetch_triggers using sqlite_master (type='trigger')
- Implement generate_table for SQLite CREATE TABLE syntax
- Implement generate_index for SQLite CREATE INDEX syntax
- Implement generate_foreign_key (inline with table or ALTER TABLE)
- Implement generate_view for SQLite CREATE VIEW syntax
- Implement generate_trigger for SQLite CREATE TRIGGER syntax
- Implement capability methods (most features = false)
- Implement database_version detection (parse SQLite version)
- Handle SQLite limitations gracefully

### 2. SQLite System Catalog Queries
**Query Implementations**:

**Tables**:
```sql
SELECT
  name,
  sql
FROM sqlite_master
WHERE type = 'table'
  AND name NOT LIKE 'sqlite_%'
ORDER BY name;
```

**Column Information (PRAGMA)**:
```sql
PRAGMA table_info(table_name);
-- Returns: cid, name, type, notnull, dflt_value, pk
```

**Indexes**:
```sql
-- List indexes for table
PRAGMA index_list(table_name);
-- Returns: seq, name, unique, origin, partial

-- Get index columns
PRAGMA index_info(index_name);
-- Returns: seqno, cid, name
```

**Foreign Keys**:
```sql
PRAGMA foreign_key_list(table_name);
-- Returns: id, seq, table, from, to, on_update, on_delete, match
```

**Views**:
```sql
SELECT
  name,
  sql
FROM sqlite_master
WHERE type = 'view'
ORDER BY name;
```

**Triggers**:
```sql
SELECT
  name,
  tbl_name,
  sql
FROM sqlite_master
WHERE type = 'trigger'
ORDER BY name;
```

### 3. SQLite Type Mapping
**Files**:
- `lib/better_structure_sql/adapters/sqlite_adapter.rb` (type_mapper method)

**SQLite Type Affinities**:
- TEXT: For text/varchar/char types
- NUMERIC: For numeric types without specified precision
- INTEGER: For integer types
- REAL: For floating point types
- BLOB: For binary data

**Mappings**:
- PostgreSQL VARCHAR → SQLite TEXT
- PostgreSQL TEXT → SQLite TEXT
- PostgreSQL INTEGER → SQLite INTEGER
- PostgreSQL BIGINT → SQLite INTEGER (64-bit)
- PostgreSQL BOOLEAN → SQLite INTEGER (0/1)
- PostgreSQL TIMESTAMP → SQLite TEXT (ISO8601)
- PostgreSQL DATE → SQLite TEXT (ISO8601)
- PostgreSQL TIME → SQLite TEXT (ISO8601)
- PostgreSQL DECIMAL → SQLite REAL or TEXT (precision preservation)
- PostgreSQL BYTEA → SQLite BLOB
- PostgreSQL JSON → SQLite TEXT (JSON string)
- PostgreSQL ARRAY → SQLite TEXT (JSON array string)
- PostgreSQL UUID → SQLite TEXT (36 chars)
- PostgreSQL ENUM → SQLite TEXT + CHECK constraint
- PostgreSQL SERIAL → SQLite INTEGER PRIMARY KEY AUTOINCREMENT

### 4. SQLite SQL Generation
**Tasks**:
- Generate CREATE TABLE with SQLite syntax
- Handle AUTOINCREMENT (only for INTEGER PRIMARY KEY)
- Generate PRIMARY KEY inline or as table constraint
- Generate UNIQUE constraints inline or as table constraint
- Generate CHECK constraints inline
- Generate DEFAULT values with SQLite syntax
- Generate FOREIGN KEY constraints inline (PRAGMA foreign_keys=ON required)
- Generate CREATE INDEX with SQLite options
- Generate CREATE VIEW with SQLite syntax
- Generate CREATE TRIGGER with timing (BEFORE/AFTER/INSTEAD OF)
- Handle trigger events (INSERT/UPDATE/DELETE)
- No stored procedures (not supported)
- No custom types (not supported)
- No extensions (not supported)

**SQLite Limitations**:
- No ALTER TABLE ADD CONSTRAINT (foreign keys must be inline)
- No ALTER TABLE DROP COLUMN (before SQLite 3.35)
- No ALTER TABLE RENAME COLUMN (before SQLite 3.25)
- Limited ALTER TABLE support
- No stored procedures/functions
- No custom types (ENUM, composite, domain)
- No sequences (use AUTOINCREMENT)
- No materialized views
- No extensions
- Triggers are simplified (no plpgsql, basic SQL only)

### 5. SQLite Integration App
**Location**: `integration_sqlite/`

**Structure**:
- `app/` - Rails app structure
- `config/database.yml` - SQLite configuration
- `config/initializers/better_structure_sql.rb` - SQLite-specific settings
- `db/migrate/` - SQLite-compatible migrations
- `db/seeds.rb` - Sample data
- `Gemfile` - Rails + sqlite3 gem
- No Dockerfile needed (file-based database)

**Database Configuration**:
```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3

production:
  <<: *default
  database: db/production.sqlite3
```

**No Docker Required**:
- SQLite is file-based (no server process)
- Database stored in `db/*.sqlite3` files
- Can run directly on host or in Rails container
- Simpler setup than PostgreSQL/MySQL

### 6. SQLite-Compatible Migrations
**Files**:
- `integration_sqlite/db/migrate/` - Simplified migrations

**Adaptations**:
- Remove all extensions (not supported)
- Remove custom types (ENUM, composite, domain)
- Replace ENUMs with TEXT + CHECK constraint
- Remove array columns (use JSON TEXT)
- Remove composite type columns (use JSON TEXT)
- Remove stored procedures (not supported)
- Remove plpgsql functions (not supported)
- Simplify triggers (no plpgsql, basic SQL only)
- Remove materialized views (not supported)
- Remove domains (use inline CHECK)
- Keep foreign keys inline with CREATE TABLE
- Use INTEGER PRIMARY KEY AUTOINCREMENT instead of SERIAL
- Use TEXT for timestamps with CHECK for ISO8601 format

**Example Migration Adaptation**:
```ruby
# PostgreSQL version
enable_extension "uuid-ossp"
create_table :users, id: :uuid do |t|
  t.column :role, :user_role # ENUM
  t.string :tags, array: true # ARRAY
end

# SQLite version
create_table :users do |t|
  t.string :id, limit: 36, null: false
  t.string :role, null: false
  t.text :tags # JSON array as TEXT
end
add_index :users, :id, unique: true
execute <<-SQL
  CREATE TRIGGER generate_user_uuid
  AFTER INSERT ON users
  BEGIN
    UPDATE users SET id = lower(hex(randomblob(16)))
    WHERE rowid = NEW.rowid AND id IS NULL;
  END;
SQL
```

### 7. SQLite Configuration Class
**Files**:
- `lib/better_structure_sql/adapters/sqlite_config.rb`

**Settings**:
```ruby
class SqliteConfig
  attr_accessor :include_triggers # default: true
  attr_accessor :include_views # default: true
  attr_accessor :foreign_keys_enabled # default: true (PRAGMA foreign_keys=ON)
  attr_accessor :strict_mode # default: false (use STRICT tables in SQLite 3.37+)
end
```

### 8. Registry Update
**Files**:
- `lib/better_structure_sql/adapters/registry.rb`

**Tasks**:
- Register SqliteAdapter for "SQLite" adapter name
- Add adapter detection for sqlite3 ActiveRecord adapter
- Validate sqlite3 gem availability when SQLite detected
- Provide helpful error if sqlite3 gem missing

### 9. Testing Suite for SQLite
**Files**:
- `spec/adapters/sqlite_adapter_spec.rb`
- `spec/integration/sqlite_dump_spec.rb`

**Tests**:
- Unit tests for SQLite introspection queries
- Unit tests for sqlite_master parsing
- Unit tests for PRAGMA-based introspection
- Unit tests for SQLite SQL generation
- Unit tests for type affinity mapping
- Integration tests with real SQLite database
- Schema dump and load cycle
- Version storage and retrieval
- Single-file output with SQLite (recommended)
- Feature capability detection
- Foreign key handling
- Trigger creation and syntax
- View creation
- CHECK constraint generation

## Testing Requirements

### Unit Tests
- SqliteAdapter implements all BaseAdapter methods
- fetch_tables parses sqlite_master correctly
- fetch_indexes uses PRAGMA index_list/info correctly
- fetch_foreign_keys uses PRAGMA foreign_key_list correctly
- generate_table produces valid SQLite CREATE TABLE
- generate_index produces valid SQLite CREATE INDEX
- Type mapping to type affinities correct
- Capability methods return correct values (most false)
- Version detection parses SQLite version strings
- Foreign keys generated inline with table
- AUTOINCREMENT only for INTEGER PRIMARY KEY

### Integration Tests
- Full schema dump with SQLite database
- Schema load restores database correctly
- Foreign keys work (PRAGMA foreign_keys=ON)
- Indexes created successfully
- Views created successfully
- Triggers created successfully
- Schema versioning works with SQLite
- Single-file output recommended
- Multi-file output works but less useful

### Comparison Tests
- Dump SQLite database with BetterStructureSql
- Use `.schema` command in sqlite3 CLI
- Compare output completeness
- Verify deterministic ordering

### Edge Cases
- Empty SQLite database
- Tables without explicit PRIMARY KEY
- Tables with INTEGER PRIMARY KEY AUTOINCREMENT
- Foreign keys with circular dependencies
- Views depending on other views
- Triggers with BEFORE/AFTER/INSTEAD OF
- CHECK constraints with complex expressions
- Reserved keywords in table/column names
- Large BLOB columns
- JSON columns stored as TEXT

## Success Criteria

- SqliteAdapter passes all unit tests
- Integration app runs successfully with SQLite
- Full dump/load cycle works correctly
- Schema output is deterministic
- Schema versioning stores and retrieves SQLite schemas
- 60%+ feature parity with PostgreSQL (limited by SQLite capabilities)
- Performance: sub-second dumps for typical schemas
- Documentation complete for SQLite usage
- CI testing includes SQLite

## Dependencies

### External Dependencies
- sqlite3 gem (>= 1.4)
- SQLite 3.35+ (recommended, 3.25+ minimum)
- No Docker required (file-based)
- Rails 7.0+ with sqlite3 adapter

### Internal Dependencies
- Phase 1 adapter infrastructure (complete)
- BaseAdapter interface
- Registry with adapter detection
- Configuration with SqliteConfig
- Introspection delegation
- Generator adapter awareness

### Integration App Dependencies
- No Docker service needed
- SQLite-compatible migrations
- sqlite3 gem in integration app
- Simplified schema for SQLite limitations

## Performance Targets

- 100 tables: < 2 seconds (file-based, very fast)
- 500 tables: < 10 seconds
- Memory usage: < 100MB increase
- Deterministic output: 100% identical on repeated dumps
- File I/O optimization: Single file recommended for SQLite

## Special Considerations

### Foreign Key Constraints
- Must be defined inline with CREATE TABLE
- Cannot use ALTER TABLE ADD CONSTRAINT (SQLite limitation)
- Require PRAGMA foreign_keys=ON to enforce
- Document this requirement clearly

### AUTOINCREMENT Behavior
- Only valid for INTEGER PRIMARY KEY
- Different from PostgreSQL SERIAL
- Creates sqlite_sequence table
- Document usage carefully

### Type System Simplification
- SQLite uses type affinities, not strict types
- Map PostgreSQL types to appropriate affinities
- Document type conversions
- Warn about precision loss for DECIMAL → REAL

### Trigger Limitations
- No plpgsql support
- Basic SQL expressions only
- No function calls (limited built-in functions)
- BEFORE/AFTER/INSTEAD OF timing
- Document simplified trigger syntax

### Schema Modification Limitations
- Limited ALTER TABLE support
- Foreign keys must be in CREATE TABLE
- Schema changes may require table recreation
- Document migration challenges

## Keywords

SQLite adapter implementation, sqlite3 gem integration, sqlite_master queries, PRAGMA statements, PRAGMA table_info, PRAGMA index_list, PRAGMA index_info, PRAGMA foreign_key_list, SQLite SQL dialect, CREATE TABLE SQLite syntax, INTEGER PRIMARY KEY AUTOINCREMENT, SQLite type affinities, TEXT NUMERIC INTEGER REAL BLOB, type affinity mapping, PostgreSQL to SQLite conversion, ENUM to TEXT CHECK constraint, array to JSON TEXT, composite type to JSON, UUID to TEXT, TIMESTAMP to TEXT ISO8601, SQLite triggers, CREATE TRIGGER timing, BEFORE AFTER INSTEAD OF, SQLite views, SQLite limitations, no stored procedures, no custom types, no extensions, no sequences, no materialized views, foreign keys inline, PRAGMA foreign_keys ON, ALTER TABLE limitations, SQLite 3.35 features, STRICT tables SQLite 3.37, SqliteConfig settings, integration_sqlite app, SQLite-compatible migrations, file-based database, no Docker needed, sqlite3 CLI .schema command, deterministic SQLite dump, schema versioning SQLite, single-file output recommended, performance targets SQLite, sqlite_sequence table, type precision loss, simplified trigger syntax, schema modification challenges, 60% feature parity, SQLite version detection, type system simplification
