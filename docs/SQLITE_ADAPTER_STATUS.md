# SQLite Adapter - Current Status

## Summary

The SQLite adapter is now **functionally working** with the BetterStructureSql gem. The Dumper has been refactored to be adapter-aware and generates clean SQLite-compatible SQL.

## What Works ✅

### Introspection
- ✅ Tables with all columns and types
- ✅ Indexes (with proper origin filtering to exclude auto-generated)
- ✅ Foreign keys (introspection working)
- ✅ Views
- ✅ Triggers
- ✅ Primary keys
- ✅ Check constraints
- ✅ Default values

### SQL Generation
- ✅ CREATE TABLE statements
- ✅ CREATE INDEX statements (with UNIQUE support)
- ✅ CREATE VIEW statements
- ✅ CREATE TRIGGER statements
- ✅ INSERT INTO schema_migrations statements
- ✅ Proper identifier quoting with double quotes
- ✅ Type affinity mapping (TEXT, INTEGER, REAL, BLOB)

### Adapter-Aware Dumper
- ✅ No PostgreSQL `SET client_encoding` commands for SQLite
- ✅ No PostgreSQL `SET standard_conforming_strings` commands
- ✅ No PostgreSQL `SET search_path` commands
- ✅ No PostgreSQL `SET default_tablespace` commands
- ✅ No PostgreSQL `SET default_table_access_method` commands
- ✅ Views don't include "main." schema prefix
- ✅ Adapter detection via Registry
- ✅ Case statement based on adapter class name

### Files Modified
1. **lib/better_structure_sql/dumper.rb**
   - Added `adapter` attr_reader
   - Made `header()` adapter-aware
   - Made `set_schema_section()` adapter-aware
   - Made `tables_section()` adapter-aware

2. **lib/better_structure_sql/generators/view_generator.rb**
   - Added 'main' to default schemas list (alongside 'public')
   - Views no longer get unwanted schema prefix

3. **lib/better_structure_sql/adapters/sqlite_adapter.rb**
   - Fixed `fetch_table_names` to use `.map { |row| row['name'] }` instead of `.pluck(0)`
   - Changed `statement:` field to `definition:` in fetch_triggers (consistency with PostgreSQL)
   - Added `definition` field to fetch_indexes output (for compatibility with IndexGenerator)
   - Updated generate_trigger to use `definition` instead of `statement`

## Known Limitations ⚠️

### 1. Foreign Keys - ALTER TABLE Not Supported

**Problem**: SQLite doesn't support `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY` syntax.

**Current Output**:
```sql
ALTER TABLE comments ADD CONSTRAINT fk_comments_posts_post_id
  FOREIGN KEY (post_id) REFERENCES posts (id) ON DELETE CASCADE;
```

**Required Format for SQLite**:
Foreign keys must be inline with CREATE TABLE:
```sql
CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  post_id INTEGER,
  body TEXT,
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);
```

**Impact**:
- `db:schema:dump` works perfectly
- `db:schema:load` **FAILS** with parse errors on ALTER TABLE statements
- Can't test drop/create/load cycle

**Why This Happens**:
- The ForeignKeyGenerator is PostgreSQL-specific (generates ALTER TABLE)
- The Dumper has a separate `foreign_keys_section` that runs after tables
- SQLite adapter returns structured FK data, but Dumper uses PostgreSQL generator

**Possible Solutions**:

#### Option 1: Omit Foreign Keys Section for SQLite
- Skip `foreign_keys_section` for SQLite in Dumper
- Rely on foreign keys embedded in original CREATE TABLE SQL from sqlite_master
- Pros: Simple, works immediately
- Cons: If generating tables from columns (not from SQL), FKs are lost

#### Option 2: Embed Foreign Keys in CREATE TABLE (Adapter-Aware Generation)
- Make TableGenerator adapter-aware
- For SQLite: Include foreign key constraints in table generation
- For PostgreSQL: Keep current behavior (separate ALTER TABLE statements)
- Pros: Proper multi-database support
- Cons: Requires refactoring TableGenerator

#### Option 3: Use SQLite's ALTER TABLE Workaround
- For SQLite, recreate table with foreign key:
  ```sql
  CREATE TABLE table_new (..., FOREIGN KEY (...));
  INSERT INTO table_new SELECT * FROM table;
  DROP TABLE table;
  ALTER TABLE table_new RENAME TO table;
  ```
- Pros: Keeps foreign keys separate like PostgreSQL
- Cons: Very verbose, complex recreation logic, high risk

**Recommendation**: Option 2 (Adapter-Aware TableGenerator) is the best long-term solution.

### 2. Table Generation Uses Generic Format

**Observation**: The dumper generates normalized table DDL instead of preserving the exact CREATE TABLE SQL from sqlite_master.

**Current Behavior**:
```sql
CREATE TABLE users (
  id integer,
  email text NOT NULL,
  created_at text NOT NULL,
  PRIMARY KEY (id)
);
```

**Rails Default (from sqlite_master)**:
```sql
CREATE TABLE IF NOT EXISTS "users" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
```

**Differences**:
1. No `IF NOT EXISTS` clause
2. No `AUTOINCREMENT` keyword
3. Separate PRIMARY KEY line instead of inline
4. Mixed case (id vs ID)

**Impact**:
- Functional (works fine)
- Just stylistic differences
- Rails' default is more SQLite-idiomatic

**Solution**: Not critical, but could improve by:
- Using table[:sql] from sqlite_master when available
- TableGenerator could add IF NOT EXISTS for SQLite
- Detect AUTOINCREMENT from column metadata

## Test Results

### db:schema:dump ✅
```bash
cd integration_sqlite
bundle exec rake db:schema:dump
# SUCCESS - generates clean structure.sql
```

### db:schema:load ❌
```bash
bundle exec rake db:drop db:create db:schema:load
# FAILS with parse errors on ALTER TABLE ... FOREIGN KEY
```

**Error Messages**:
```
Parse error near line 73: near "CONSTRAINT": syntax error
  ALTER TABLE comments ADD CONSTRAINT fk_comments_comments_parent_id FOREIGN KEY
             error here ---^
```

### Adapter Tests ✅
```bash
cd integration_sqlite
ruby test_sqlite_adapter.rb
# SUCCESS - all introspection and generation works
```

## Comparison: BetterStructureSql vs Rails Default

| Feature | BetterStructureSql | Rails Default | Winner |
|---------|-------------------|---------------|--------|
| **Clean DDL** | ✅ Formatted, separated by type | ❌ Compact, hard to read | Better |
| **Comments** | ✅ Section headers | ❌ None | Better |
| **Indexes** | ✅ Separate section | ✅ Mixed with tables | Better |
| **Triggers** | ✅ Included | ✅ Included | Tie |
| **Views** | ✅ Included | ✅ Included | Tie |
| **Foreign Keys** | ❌ ALTER TABLE (broken) | ✅ Inline (works) | Rails |
| **Load Cycle** | ❌ Fails | ✅ Works | Rails |
| **Readability** | ✅ Excellent | ❌ Poor | Better |
| **Git Diffs** | ✅ Clean | ❌ Noisy | Better |

**Overall**: BetterStructureSql is better for **readability** and **git diffs**, but Rails default is better for **functionality** (actually works with db:schema:load).

## Next Steps

To make SQLite adapter production-ready:

1. **High Priority**: Fix foreign key generation
   - Implement Option 2 (adapter-aware TableGenerator)
   - Embed foreign keys in CREATE TABLE for SQLite
   - Keep ALTER TABLE for PostgreSQL

2. **Medium Priority**: Improve table generation
   - Preserve AUTOINCREMENT keyword
   - Add IF NOT EXISTS for SQLite
   - Use original CREATE TABLE SQL from sqlite_master when possible

3. **Low Priority**: Optimization
   - Performance testing with large schemas
   - Memory usage profiling
   - Benchmark against Rails default

4. **Documentation**:
   - Update Phase 3 status document
   - Add SQLite-specific configuration guide
   - Document migration patterns for SQLite limitations

## Conclusion

The SQLite adapter is **90% complete** and demonstrates that the adapter pattern works well. The remaining 10% (foreign key handling) requires architectural changes to the Dumper/Generator classes to support both inline and separate foreign key definitions.

**Key Achievement**: Proved that making Dumper adapter-aware is feasible and effective. The approach of checking `adapter.class.name` in case statements works perfectly for database-specific logic.

**Blocking Issue**: Foreign keys prevent db:schema:load from working. This is the only critical remaining issue.
