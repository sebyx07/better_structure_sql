# Large Schema Generator - Test Data Creation

## Purpose

Generate a realistic large database schema in the integration app to demonstrate:
1. The problems with monolithic `structure.sql` files (4,000+ lines)
2. The benefits of multi-file schema output
3. Performance characteristics with hundreds of database objects

## Quick Start

```bash
cd integration

# Generate large schema
rails db:seed

# See current structure.sql size
rails db:schema:dump
wc -l db/structure.sql
# Expected: ~4,000-5,000 lines

# Open and experience the navigation pain
code db/structure.sql
```

## What Gets Generated

### Database Objects

- **50 tables** - `large_table_000` through `large_table_049`
  - Each with ~10 columns (name, description, status, price, active, metadata, ip_address, external_id, timestamps)
  - Realistic column types: string, text, integer, decimal, boolean, jsonb, inet, uuid
  - NOT NULL constraints, default values

- **150 indexes** - 3 per table
  - Single column indexes (name, status)
  - Composite indexes (active + status)
  - Named indexes with consistent convention

- **50 check constraints** - 1 per table
  - Status range validation (0-10)

- **25 foreign keys** - Linking tables together
  - `large_table_000` → `large_table_001`
  - `large_table_002` → `large_table_003`
  - etc.

- **20 views** - `large_view_00` through `large_view_19`
  - Filter active records from corresponding tables
  - SELECT id, name, status, active, created_at

- **10 functions** - `calculate_total_0` through `calculate_total_9`
  - plpgsql functions with calculations
  - Multi-line to increase LOC

- **15 triggers** - On first 15 tables
  - UPDATE timestamp triggers
  - Each with dedicated trigger function
  - `trg_large_table_NNN_update_timestamp`

### Total Statistics

- **~270 database objects**
- **~4,000-5,000 lines** in structure.sql
- **~150KB-250KB** file size

## Schema Generator Code

### Location

Choose one:
- `integration/db/seeds.rb` - Easy to regenerate with `rails db:seed`
- `integration/db/migrate/XXXXXX_create_large_schema.rb` - Permanent in migrations

### Implementation

```ruby
# integration/db/seeds.rb

puts "Generating large schema to demonstrate multi-file feature..."

# Generate 50 tables with realistic structure
50.times do |i|
  table_name = "large_table_#{i.to_s.rjust(3, '0')}"

  ActiveRecord::Migration.create_table table_name do |t|
    t.string :name, null: false
    t.text :description
    t.integer :status, default: 0
    t.decimal :price, precision: 10, scale: 2
    t.boolean :active, default: true
    t.jsonb :metadata, default: {}
    t.inet :ip_address
    t.uuid :external_id
    t.timestamps
  end

  # Add 3 indexes per table
  ActiveRecord::Migration.add_index table_name, :name
  ActiveRecord::Migration.add_index table_name, :status
  ActiveRecord::Migration.add_index table_name, [:active, :status],
                                     name: "idx_#{table_name}_active_status"

  # Add check constraints
  ActiveRecord::Base.connection.execute <<~SQL
    ALTER TABLE #{table_name}
    ADD CONSTRAINT chk_#{table_name}_status
    CHECK (status >= 0 AND status <= 10);
  SQL
end

# Generate foreign keys between tables
25.times do |i|
  source_table = "large_table_#{(i * 2).to_s.rjust(3, '0')}"
  target_table = "large_table_#{((i * 2) + 1).to_s.rjust(3, '0')}"

  ActiveRecord::Migration.add_column source_table, :related_id, :bigint
  ActiveRecord::Migration.add_foreign_key source_table, target_table, column: :related_id
end

# Generate 20 views
20.times do |i|
  view_name = "large_view_#{i.to_s.rjust(2, '0')}"
  table_name = "large_table_#{(i * 2).to_s.rjust(3, '0')}"

  ActiveRecord::Base.connection.execute <<~SQL
    CREATE VIEW #{view_name} AS
    SELECT id, name, status, active, created_at
    FROM #{table_name}
    WHERE active = true;
  SQL
end

# Generate 10 functions
10.times do |i|
  function_name = "calculate_total_#{i}"

  ActiveRecord::Base.connection.execute <<~SQL
    CREATE OR REPLACE FUNCTION #{function_name}(base_amount numeric)
    RETURNS numeric AS $$
    BEGIN
      -- Complex calculation to make function multi-line
      RETURN base_amount * 1.#{i} + #{i * 10};
    END;
    $$ LANGUAGE plpgsql IMMUTABLE;
  SQL
end

# Generate 15 triggers
15.times do |i|
  table_name = "large_table_#{i.to_s.rjust(3, '0')}"
  trigger_name = "trg_#{table_name}_update_timestamp"

  # First create the trigger function
  ActiveRecord::Base.connection.execute <<~SQL
    CREATE OR REPLACE FUNCTION update_timestamp_#{i}()
    RETURNS trigger AS $$
    BEGIN
      NEW.updated_at = CURRENT_TIMESTAMP;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
  SQL

  # Then create the trigger
  ActiveRecord::Base.connection.execute <<~SQL
    CREATE TRIGGER #{trigger_name}
    BEFORE UPDATE ON #{table_name}
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp_#{i}();
  SQL
end

puts "✓ Large schema generated successfully!"
puts ""
puts "Statistics:"
puts "  - 50 tables (each with ~10 columns)"
puts "  - 150 indexes (3 per table)"
puts "  - 50 check constraints"
puts "  - 25 foreign keys"
puts "  - 20 views"
puts "  - 10 functions"
puts "  - 15 triggers"
puts ""
puts "Total database objects: ~270"
puts ""
puts "Next steps:"
puts "  1. rails db:schema:dump"
puts "  2. wc -l db/structure.sql  # See file size"
puts "  3. code db/structure.sql   # Experience navigation pain"
```

## Demonstrating the Problem

### Single-File Pain Points

**Navigation:**
```bash
$ code db/structure.sql
# Try to find: large_table_037
# Must: Scroll or search through 4,000+ lines
# Time: 10-30 seconds
```

**Git Diff:**
```bash
# Add one new table
$ rails generate migration AddNewTable
$ rails db:migrate
$ rails db:schema:dump

$ git diff db/structure.sql
# Shows: ALL 4,287 lines with one small change buried inside
```

**Code Review:**
```bash
# Reviewer must:
# 1. Download 4,287 line diff
# 2. Search for actual changes
# 3. Context is lost in noise
```

**Editor Performance:**
```bash
# VS Code / Sublime / Atom:
# - Initial load: 2-5 seconds
# - Syntax highlighting: Slow or disabled
# - Find/replace: Laggy
# - Large file warnings appear
```

### Multi-File Benefits (After Implementation)

**Navigation:**
```bash
$ ls db/schema/4_tables/
000001.sql  000002.sql  000003.sql ... 000010.sql

# Each file ~250 lines, easy to browse
# Found large_table_037 in: db/schema/4_tables/000008.sql
# Time: 2-3 seconds
```

**Git Diff:**
```bash
$ git diff db/schema/
diff --git a/db/schema/4_tables/000011.sql b/db/schema/4_tables/000011.sql
new file mode 100644
+++ b/db/schema/4_tables/000011.sql
@@ -0,0 +1,48 @@
+CREATE TABLE new_table (
+  id bigint PRIMARY KEY,
+  ...
+);

# Only shows new file, 48 lines total
```

**Code Review:**
```bash
# Reviewer sees:
# - New file: db/schema/4_tables/000011.sql (48 lines)
# - Clear, focused change
# - Easy to approve
```

**Editor Performance:**
```bash
# Any editor:
# - Instant load (< 100ms per file)
# - Full syntax highlighting
# - Fast find/replace
# - No performance issues
```

## Cleanup

### Reset Database

```bash
cd integration
rails db:drop db:create db:migrate
```

### Remove Generated Schema

```bash
# If you want to start fresh
rm db/structure.sql
# or
rm -rf db/schema/
```

## Comparison Table

| Metric | Single File | Multi-File |
|--------|-------------|------------|
| Total Lines | 4,287 | 4,287 (split across 72 files) |
| Average File Size | 4,287 lines | 60 lines per file |
| Find Table Time | 10-30 sec (search) | 2-3 sec (browse dir) |
| Editor Load Time | 2-5 sec | < 100ms per file |
| Git Diff Size | Full file (4,287 lines) | Changed files only (50-200 lines typical) |
| Merge Conflict Resolution | Very difficult | Easy (isolated to specific files) |
| Code Review | Painful | Pleasant |
| Navigation | Scroll/search | Directory structure |

## Next Steps

1. **Generate the schema**: `cd integration && rails db:seed`
2. **Experience the pain**: `code db/structure.sql` (4,000+ lines)
3. **Implement Phase 1**: Multi-file output infrastructure
4. **Compare**: `db/structure.sql` vs `db/schema/` directory
5. **Celebrate**: Clean, navigable schema files!

## Future Enhancements

**Scaling Up:**
- Generate 500 tables for stress testing
- Generate 5,000 tables for extreme scenarios
- Measure memory usage and performance

**Variation Testing:**
- Some tables with 100+ columns (large single objects)
- Complex views with joins
- Recursive functions
- Many-to-many relationships with junction tables

**Benchmark Suite:**
- Dump time comparison (single vs multi)
- Load time comparison
- Memory usage tracking
- File I/O performance
