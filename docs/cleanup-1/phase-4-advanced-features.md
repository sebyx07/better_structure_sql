# Phase 4: Advanced Features Implementation

**Priority**: FUTURE / OPTIONAL
**Estimated Effort**: 5-7 days
**Goal**: Implement features claimed in documentation or add to roadmap

## Todo List

### Dependency Resolution (HIGH value)

- [ ] **Implement view dependency detection**
  - Parse view SQL definitions for referenced tables/views
  - File: `lib/better_structure_sql/dependency_resolver.rb:25-40`
  - Method: `extract_dependencies_from_sql(sql, object_type)`
  - Use regex or SQL parser gem (pg_query)

- [ ] **Implement function dependency detection**
  - Parse function bodies for referenced types, tables, other functions
  - File: `lib/better_structure_sql/dependency_resolver.rb:42-55`
  - Handle PostgreSQL, MySQL syntax differences

- [ ] **Integrate DependencyResolver into Dumper**
  - File: `lib/better_structure_sql/dumper.rb:231-245`
  - Method: `sort_objects_by_dependencies(objects, object_type)`
  - Use before generating each section
  - Fallback to alphabetical if cycle detected

- [ ] **Add dependency resolution tests**
  - File: `spec/integration/dependency_ordering_spec.rb` (create new)
  - Test: view1 depends on view2 → view2 generated first
  - Test: circular dependency → graceful fallback
  - Test: function calls another function → correct order

- [ ] **Document dependency resolution algorithm**
  - File: `docs/architecture/dependency-resolution.md`
  - Explain topological sort implementation
  - Document cycle detection and fallback behavior
  - List limitations (SQL parsing edge cases)

### Partitioned Tables (PostgreSQL)

- [ ] **Implement partitioned table introspection**
  - Query: `pg_partitioned_table`, `pg_inherits` system catalogs
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:285-320` (new section)
  - Method: `fetch_partitioned_tables` returns parent tables
  - Method: `fetch_partitions(parent_table)` returns child partitions

- [ ] **Create PartitionedTableGenerator**
  - File: `lib/better_structure_sql/generators/partitioned_table_generator.rb` (create new)
  - Generate: `CREATE TABLE parent (...) PARTITION BY RANGE (column)`
  - Generate: `CREATE TABLE partition PARTITION OF parent FOR VALUES FROM (...) TO (...)`
  - Support: RANGE, LIST, HASH partitioning

- [ ] **Add partitioned table tests**
  - File: `integration/db/migrate/012_create_partitioned_tables.rb` (create new)
  - Test: RANGE partition by date (monthly partitions)
  - Test: LIST partition by category
  - Test: HASH partition by id
  - File: `spec/generators/partitioned_table_generator_spec.rb` (create new)

- [ ] **Update documentation**
  - File: `README.md` - Add back "✅ Partitioned Tables"
  - File: `docs/postgresql/partitioned-tables.md` (create new)
  - Tutorial: When to use partitioning, how BetterStructureSql handles it

### Table Inheritance (PostgreSQL)

- [ ] **Implement table inheritance introspection**
  - Query: `pg_inherits` system catalog
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:322-350` (new section)
  - Method: `fetch_inherited_tables` returns parent-child relationships

- [ ] **Update TableGenerator for inheritance**
  - File: `lib/better_structure_sql/generators/table_generator.rb:70-85`
  - Add: `INHERITS (parent_table)` clause
  - Handle: Column inheritance (don't duplicate inherited columns)

- [ ] **Add table inheritance tests**
  - File: `integration/db/migrate/013_create_inherited_tables.rb` (create new)
  - Test: Person parent, Employee child inherits columns
  - Test: Multi-level inheritance (GrandChild → Child → Parent)
  - File: `spec/generators/table_generator_spec.rb` - Add inheritance examples

- [ ] **Document inheritance support**
  - File: `README.md` - Add "✅ Table Inheritance"
  - File: `docs/postgresql/table-inheritance.md` (create new)
  - Tutorial: When to use inheritance vs foreign keys

### Comments on Database Objects

- [ ] **Implement comment introspection**
  - Query: `pg_description` catalog for PostgreSQL
  - Query: `information_schema.tables.table_comment` for MySQL
  - File: `lib/better_structure_sql/adapters/base_adapter.rb:95-100` (interface)
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:352-380`
  - Method: `fetch_comments(object_type)` returns hash by object name

- [ ] **Create CommentGenerator**
  - File: `lib/better_structure_sql/generators/comment_generator.rb` (create new)
  - Generate: `COMMENT ON TABLE users IS 'User accounts and profiles'`
  - Generate: `COMMENT ON COLUMN users.email IS 'Unique email address'`
  - Support: tables, columns, indexes, views, functions

- [ ] **Integrate comments into Dumper**
  - File: `lib/better_structure_sql/dumper.rb:72-75` (add section)
  - Add: Comments section after each object type (or inline with object)
  - Respect: `config.include_comments` toggle

- [ ] **Add comment tests**
  - File: `integration/db/migrate/014_add_comments.rb` (create new)
  - Use: `connection.execute("COMMENT ON TABLE ...")` in migration
  - File: `spec/generators/comment_generator_spec.rb` (create new)

- [ ] **Make include_comments functional**
  - File: `lib/better_structure_sql/configuration.rb:24`
  - Current: Toggle exists but does nothing
  - After: Toggle controls comment generation
  - Default: `false` (opt-in to avoid noise)

### PostgreSQL Rules

- [ ] **Implement rule introspection**
  - Query: `pg_rules` system view
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:382-405`
  - Method: `fetch_rules` returns rule definitions

- [ ] **Create RuleGenerator**
  - File: `lib/better_structure_sql/generators/rule_generator.rb` (create new)
  - Generate: `CREATE RULE rule_name AS ON event TO table DO INSTEAD ...`
  - Support: INSERT, UPDATE, DELETE events
  - Note: Rules are deprecated in favor of triggers, low priority

- [ ] **Add rule tests**
  - File: `integration/db/migrate/015_create_rules.rb` (create new)
  - Test: Simple audit rule
  - File: `spec/generators/rule_generator_spec.rb` (create new)

- [ ] **Document rules support**
  - File: `docs/postgresql/rules.md` (create new)
  - Note: Deprecated feature, triggers preferred
  - Explain why BetterStructureSql still supports (legacy databases)

### Cross-Database Type Mapping (Future)

- [ ] **Design type mapping system**
  - File: `lib/better_structure_sql/type_mapper.rb` (create new)
  - Method: `map_type(from_adapter, to_adapter, type_name)`
  - Examples: PostgreSQL ARRAY → MySQL JSON, ENUM → VARCHAR+CHECK

- [ ] **Implement type translator**
  - Use: `TypeMapper` in generators when target database differs from source
  - Configuration: `config.target_adapter = :mysql` (optional)
  - Purpose: Generate MySQL-compatible SQL from PostgreSQL introspection

- [ ] **Add migration guide documentation**
  - File: `docs/guides/postgresql-to-mysql-migration.md` (create new)
  - Document: What translates cleanly, what requires manual changes
  - Examples: Partitioned tables (PostgreSQL) → manual partitioning (MySQL)

- [ ] **Create compatibility checker**
  - File: `lib/better_structure_sql/compatibility_checker.rb` (create new)
  - Method: `check_compatibility(source_schema, target_adapter)`
  - Returns: List of incompatible features with suggestions
  - Example: "PostgreSQL ARRAY columns not supported in SQLite, consider JSON"

## Acceptance Criteria

### Dependency Resolution
✅ Views ordered by dependencies, not alphabetically
✅ Functions ordered by call graph
✅ Circular dependencies detected and handled gracefully
✅ Integration tests verify correct ordering

### Partitioned Tables
✅ PostgreSQL partitioned tables introspected
✅ Parent and child partitions generated correctly
✅ RANGE, LIST, HASH partitioning supported
✅ Tests cover all partition types

### Table Inheritance
✅ PostgreSQL table inheritance detected
✅ INHERITS clause generated
✅ Inherited columns not duplicated
✅ Multi-level inheritance works

### Comments
✅ Comments on all object types supported
✅ `include_comments` toggle functional
✅ PostgreSQL and MySQL comments introspected
✅ SQLite comments skipped gracefully

### Rules
✅ PostgreSQL rules introspected and generated
✅ Documentation explains deprecation
✅ Tests verify rule creation

## Files to Create

- `lib/better_structure_sql/generators/partitioned_table_generator.rb`
- `lib/better_structure_sql/generators/comment_generator.rb`
- `lib/better_structure_sql/generators/rule_generator.rb`
- `lib/better_structure_sql/type_mapper.rb`
- `lib/better_structure_sql/compatibility_checker.rb`
- `spec/generators/partitioned_table_generator_spec.rb`
- `spec/generators/comment_generator_spec.rb`
- `spec/generators/rule_generator_spec.rb`
- `spec/integration/dependency_ordering_spec.rb`
- `integration/db/migrate/012_create_partitioned_tables.rb`
- `integration/db/migrate/013_create_inherited_tables.rb`
- `integration/db/migrate/014_add_comments.rb`
- `integration/db/migrate/015_create_rules.rb`
- `docs/architecture/dependency-resolution.md`
- `docs/postgresql/partitioned-tables.md`
- `docs/postgresql/table-inheritance.md`
- `docs/postgresql/rules.md`
- `docs/guides/postgresql-to-mysql-migration.md`

## Files to Modify

- `lib/better_structure_sql/dependency_resolver.rb` - Add SQL parsing
- `lib/better_structure_sql/dumper.rb` - Integrate DependencyResolver
- `lib/better_structure_sql/adapters/postgresql_adapter.rb` - Add introspection
- `lib/better_structure_sql/generators/table_generator.rb` - Add INHERITS
- `lib/better_structure_sql/configuration.rb` - Make toggles functional
- `README.md` - Add feature checkmarks when implemented

## Priority Order

1. **Dependency Resolution** (HIGH) - Most impactful, affects correctness
2. **Comments** (MEDIUM) - Easy win, toggle already exists
3. **Partitioned Tables** (MEDIUM) - Common use case
4. **Table Inheritance** (LOW) - Less common, niche use case
5. **Rules** (LOW) - Deprecated feature, rarely used
6. **Type Mapping** (FUTURE) - Complex, requires design discussion
