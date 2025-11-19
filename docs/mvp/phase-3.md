# Phase 3: Advanced PostgreSQL Features

Add support for views, triggers, functions, and advanced PostgreSQL objects.

## Objectives

- Complete PostgreSQL feature support
- Add views (regular and materialized)
- Add functions and triggers
- Add comments and descriptions
- Performance optimization

## Tasks

### 1. Views Support

**File**: `lib/better_structure_sql/generators/view_generator.rb`

- [ ] Implement view introspection from pg_views
- [ ] Generate CREATE VIEW statements
- [ ] Support view dependencies ordering
- [ ] Handle view columns and types
- [ ] Support CHECK OPTION
- [ ] Write view generator specs

### 2. Materialized Views

**File**: `lib/better_structure_sql/generators/materialized_view_generator.rb`

- [ ] Implement materialized view introspection
- [ ] Generate CREATE MATERIALIZED VIEW
- [ ] Support indexes on materialized views
- [ ] Handle WITH DATA / WITH NO DATA
- [ ] Support tablespace specification
- [ ] Write materialized view specs

### 3. Functions (Stored Procedures)

**File**: `lib/better_structure_sql/generators/function_generator.rb`

- [ ] Introspect functions from pg_proc
- [ ] Generate CREATE FUNCTION statements
- [ ] Support function parameters:
  - IN, OUT, INOUT parameters
  - DEFAULT values
  - VARIADIC parameters
- [ ] Support return types:
  - Scalar types
  - TABLE return type
  - SETOF types
- [ ] Support function attributes:
  - LANGUAGE (plpgsql, sql)
  - IMMUTABLE/STABLE/VOLATILE
  - SECURITY DEFINER/INVOKER
  - COST and ROWS
- [ ] Write function generator specs

### 4. Triggers

**File**: `lib/better_structure_sql/generators/trigger_generator.rb`

- [ ] Introspect triggers from pg_trigger
- [ ] Generate CREATE TRIGGER statements
- [ ] Support trigger timing:
  - BEFORE/AFTER
  - INSTEAD OF (for views)
- [ ] Support trigger events:
  - INSERT, UPDATE, DELETE, TRUNCATE
- [ ] Support trigger scope:
  - FOR EACH ROW
  - FOR EACH STATEMENT
- [ ] Support WHEN conditions
- [ ] Link to trigger functions
- [ ] Write trigger generator specs

### 5. Rules

**File**: `lib/better_structure_sql/generators/rule_generator.rb`

- [ ] Introspect rules from pg_rules
- [ ] Generate CREATE RULE statements
- [ ] Support rule events (SELECT, INSERT, UPDATE, DELETE)
- [ ] Support INSTEAD/ALSO rules
- [ ] Write rule generator specs

### 6. Comments (Optional)

**File**: `lib/better_structure_sql/generators/comment_generator.rb`

- [ ] Introspect object comments from pg_description
- [ ] Generate COMMENT ON statements for:
  - Tables
  - Columns
  - Functions
  - Views
  - Extensions
- [ ] Add configuration option `include_comments`
- [ ] Write comment generator specs

### 7. Schemas (Multi-schema Support)

**File**: `lib/better_structure_sql/schema_handler.rb`

- [ ] Support multiple schema dumps
- [ ] Generate CREATE SCHEMA statements
- [ ] Respect search_path configuration
- [ ] Support schema-qualified object names
- [ ] Add configuration for schema filtering
- [ ] Write schema handler specs

### 8. Domain Types

**File**: `lib/better_structure_sql/generators/domain_generator.rb`

- [ ] Introspect domains from pg_type
- [ ] Generate CREATE DOMAIN statements
- [ ] Support domain constraints
- [ ] Support DEFAULT values
- [ ] Support NULL/NOT NULL
- [ ] Write domain generator specs

### 9. Collations

**File**: `lib/better_structure_sql/generators/collation_generator.rb`

- [ ] Introspect custom collations
- [ ] Generate CREATE COLLATION statements
- [ ] Support locale specification
- [ ] Write collation generator specs

### 10. Dependency Resolution

**File**: `lib/better_structure_sql/dependency_resolver.rb`

- [ ] Implement topological sort for objects
- [ ] Handle circular dependencies
- [ ] Resolve function dependencies
- [ ] Resolve view dependencies
- [ ] Resolve type dependencies
- [ ] Order objects correctly in output
- [ ] Write dependency resolver specs

### 11. Partitioned Tables

**File**: `lib/better_structure_sql/generators/partition_generator.rb`

- [ ] Detect partitioned tables
- [ ] Generate CREATE TABLE ... PARTITION BY
- [ ] Generate partition creation statements
- [ ] Support partition types:
  - RANGE partitioning
  - LIST partitioning
  - HASH partitioning
- [ ] Handle partition constraints
- [ ] Write partition generator specs

### 12. Inherited Tables

**File**: `lib/better_structure_sql/generators/inheritance_generator.rb`

- [ ] Detect table inheritance from pg_inherits
- [ ] Generate INHERITS clauses
- [ ] Order parent before child tables
- [ ] Write inheritance generator specs

### 13. Performance Optimization

**File**: `lib/better_structure_sql/introspection.rb`

- [ ] Batch SQL queries where possible
- [ ] Cache repeated queries
- [ ] Use prepared statements
- [ ] Add query result memoization
- [ ] Implement connection pooling awareness
- [ ] Write performance benchmarks

### 14. Parallel Processing (Optional)

**File**: `lib/better_structure_sql/parallel_dumper.rb`

- [ ] Parallelize independent object introspection
- [ ] Use thread pool for large databases
- [ ] Add configuration for parallelism
- [ ] Maintain deterministic output
- [ ] Write parallel processing specs

### 15. Diff Comparison Tool

**File**: `lib/better_structure_sql/differ.rb`

- [ ] Implement schema comparison
- [ ] Generate diff output
- [ ] Highlight structural changes
- [ ] Compare with pg_dump output
- [ ] Add rake task `db:schema:diff`
- [ ] Write differ specs

### 16. Extended Configuration

**File**: `lib/better_structure_sql/configuration.rb`

Add advanced config options:

- [ ] `include_views` (boolean, default: true)
- [ ] `include_materialized_views` (boolean, default: true)
- [ ] `include_functions` (boolean, default: true)
- [ ] `include_triggers` (boolean, default: true)
- [ ] `include_rules` (boolean, default: false)
- [ ] `include_comments` (boolean, default: false)
- [ ] `include_domains` (boolean, default: true)
- [ ] `schemas` (array, default: ['public'])
- [ ] `parallel` (boolean, default: false)
- [ ] `parallel_workers` (integer, default: 4)
- [ ] Write configuration specs

### 17. Comprehensive Testing

**Specs**: `spec/`

- [ ] Test complex dummy app with:
  - 10+ views with dependencies
  - 20+ functions in plpgsql
  - Triggers on multiple tables
  - Materialized views with indexes
  - Partitioned tables (3 levels)
  - Inherited tables
  - Custom domains and types
  - Multiple schemas
  - Comments on objects
- [ ] Test ordering and dependencies
- [ ] Compare output with pg_dump
- [ ] Performance benchmarks
- [ ] Large database tests (500+ objects)

### 18. Documentation

- [ ] Document all advanced features
- [ ] Add examples for each feature
- [ ] Update README with feature list
- [ ] Create troubleshooting guide
- [ ] Add performance tuning guide

## Acceptance Criteria

- [ ] Complete support for PostgreSQL features:
  - Views and materialized views
  - Functions (plpgsql, sql)
  - Triggers
  - Partitioned tables
  - Inherited tables
  - Domains and custom types
- [ ] Correct dependency ordering
- [ ] Performance acceptable for 500+ objects
- [ ] Output comparable to pg_dump in completeness
- [ ] All advanced specs passing
- [ ] Documentation complete

## Files to Create/Modify

```
lib/
  better_structure_sql/
    dependency_resolver.rb (NEW)
    differ.rb (NEW)
    parallel_dumper.rb (NEW)
    schema_handler.rb (NEW)
    generators/
      view_generator.rb (NEW)
      materialized_view_generator.rb (NEW)
      function_generator.rb (NEW)
      trigger_generator.rb (NEW)
      rule_generator.rb (NEW)
      comment_generator.rb (NEW)
      domain_generator.rb (NEW)
      collation_generator.rb (NEW)
      partition_generator.rb (NEW)
      inheritance_generator.rb (NEW)
    configuration.rb (MODIFY)
    dumper.rb (MODIFY)

spec/
  better_structure_sql/
    dependency_resolver_spec.rb (NEW)
    differ_spec.rb (NEW)
    parallel_dumper_spec.rb (NEW)
    schema_handler_spec.rb (NEW)
    generators/
      view_generator_spec.rb (NEW)
      materialized_view_generator_spec.rb (NEW)
      function_generator_spec.rb (NEW)
      trigger_generator_spec.rb (NEW)
      rule_generator_spec.rb (NEW)
      domain_generator_spec.rb (NEW)
      partition_generator_spec.rb (NEW)
  integration/
    advanced_features_spec.rb (NEW)
  performance/
    benchmark_spec.rb (NEW)
```

## Testing Strategy

Create comprehensive dummy app schema:

```sql
-- Extensions
pgcrypto, uuid-ossp, pg_trgm, hstore

-- Custom types
CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest');
CREATE DOMAIN email AS varchar(255) CHECK (VALUE ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- Partitioned table
CREATE TABLE measurements (
  id bigserial,
  created_at timestamp NOT NULL
) PARTITION BY RANGE (created_at);

-- Views
CREATE VIEW active_users AS SELECT * FROM users WHERE active = true;

-- Materialized views
CREATE MATERIALIZED VIEW user_stats AS
SELECT user_id, COUNT(*) FROM events GROUP BY user_id;

-- Functions
CREATE FUNCTION update_timestamp() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_timestamp_trigger
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_timestamp();
```

## Performance Targets

- 100 tables: < 5 seconds
- 500 tables: < 20 seconds
- 1000 tables: < 45 seconds
- With 50+ functions, 30+ views, 20+ triggers

## Next Steps

After Phase 3:
- Release v1.0.0
- Gather community feedback
- Plan Phase 4 (optional): MySQL/SQLite support
