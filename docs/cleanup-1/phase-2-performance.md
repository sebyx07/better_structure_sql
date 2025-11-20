# Phase 2: Performance Optimization

**Priority**: MEDIUM
**Estimated Effort**: 3-4 days
**Goal**: Fix N+1 queries and add performance benchmarks

## Todo List

### N+1 Query Fixes

- [ ] **Batch PostgreSQL table metadata queries**
  - Currently: `fetch_columns`, `fetch_primary_key`, `fetch_constraints` called per table
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:154-283`
  - Solution: Single query with LEFT JOIN to fetch all table metadata
  - Method: Create `fetch_all_table_metadata` returning hash by table name
  - Impact: ~10x faster for 100+ table schemas

- [ ] **Batch MySQL table metadata queries**
  - Same issue as PostgreSQL adapter
  - File: `lib/better_structure_sql/adapters/mysql_adapter.rb:140-245`
  - Query information_schema once with table_name IN (...)

- [ ] **Batch SQLite PRAGMA queries**
  - Multiple PRAGMA calls per table (table_info, foreign_key_list)
  - File: `lib/better_structure_sql/adapters/sqlite_adapter.rb:155-215`
  - Cache sqlite_master queries, minimize PRAGMA roundtrips

- [ ] **Update Introspection facade to use batched queries**
  - File: `lib/better_structure_sql/introspection.rb:45-50`
  - Change from per-table to batch-all pattern
  - Maintain backward compatibility if needed

### Performance Benchmarks

- [ ] **Create benchmark script**
  - File: `benchmarks/large_schema_benchmark.rb` (create new)
  - Test with 100, 500, 1000, 5000 table schemas
  - Measure: total time, memory usage, queries executed
  - Compare before/after N+1 fixes

- [ ] **Add benchmark rake task**
  - File: `lib/tasks/benchmark.rake` (create new)
  - Task: `rake benchmark:schema_dump[table_count]`
  - Output results table with timings

- [ ] **Generate test schemas programmatically**
  - File: `spec/support/schema_generator.rb` (create new)
  - Method: `generate_tables(count)` creates realistic test schema
  - Include indexes, foreign keys, constraints
  - Use for benchmark and stress testing

- [ ] **Add performance tests to CI**
  - File: `.github/workflows/performance.yml` (create new)
  - Run benchmarks on PR, fail if regression > 20%
  - Store results as artifacts

### Query Optimization

- [ ] **Add query result caching within dump session**
  - File: `lib/better_structure_sql/adapters/base_adapter.rb:15-20`
  - Add `@cache = {}` instance variable
  - Cache expensive queries (types, functions, extensions)
  - Clear cache after dump completes

- [ ] **Use database indexes for metadata queries**
  - Review all adapter queries for EXPLAIN ANALYZE
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb` (all queries)
  - Ensure queries hit pg_catalog indexes
  - Document slow queries and workarounds

- [ ] **Stream large result sets**
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:74-91` (fetch_indexes)
  - For 10,000+ indexes, use find_each or cursor
  - Avoid loading all results into memory

### Memory Optimization

- [ ] **Profile memory usage with large schemas**
  - Tool: `memory_profiler` gem
  - File: `benchmarks/memory_profile.rb` (create new)
  - Identify allocations for 5000+ table dump
  - Target: < 100MB memory increase

- [ ] **Implement streaming SQL generation**
  - File: `lib/better_structure_sql/dumper.rb:43-101`
  - Instead of building full SQL string, write to file incrementally
  - Pass IO object to generators instead of accumulating strings

## Acceptance Criteria

✅ No N+1 queries in adapter metadata fetching
✅ Benchmark script measures 100-5000 table dumps
✅ 1000 table dump completes in < 20 seconds
✅ Memory usage stays under 100MB for 1000 table dump
✅ Performance tests run in CI on every PR
✅ Documentation includes performance characteristics

## Files to Modify

- `lib/better_structure_sql/adapters/postgresql_adapter.rb` - Batch queries
- `lib/better_structure_sql/adapters/mysql_adapter.rb` - Batch queries
- `lib/better_structure_sql/adapters/sqlite_adapter.rb` - Batch queries
- `lib/better_structure_sql/adapters/base_adapter.rb` - Add caching
- `lib/better_structure_sql/introspection.rb` - Use batched methods
- `lib/better_structure_sql/dumper.rb` - Streaming generation
- `benchmarks/large_schema_benchmark.rb` - Create new
- `benchmarks/memory_profile.rb` - Create new
- `lib/tasks/benchmark.rake` - Create new
- `spec/support/schema_generator.rb` - Create new
- `.github/workflows/performance.yml` - Create new

## Performance Targets

| Schema Size | Current (est.) | Target | Improvement |
|-------------|---------------|--------|-------------|
| 100 tables  | ~8s           | < 5s   | 37% faster  |
| 500 tables  | ~45s          | < 20s  | 56% faster  |
| 1000 tables | ~120s         | < 30s  | 75% faster  |
| 5000 tables | Unknown       | < 3min | Baseline    |

Memory target: < 100MB increase regardless of schema size
