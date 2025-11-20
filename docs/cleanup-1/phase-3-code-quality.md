# Phase 3: Code Quality Improvements

**Priority**: LOW
**Estimated Effort**: 2-3 days
**Goal**: Refactor long methods and improve code maintainability

## Todo List

### Method Extraction (Target: 10 lines avg, 20 max)

- [ ] **Dumper#generate_sections_for_multi_file - 127 lines**
  - File: `lib/better_structure_sql/dumper.rb:102-229`
  - Extract: `write_header_file(file_writer, directory)`
  - Extract: `write_extension_sections(file_writer, directory, extensions)`
  - Extract: `write_type_sections(file_writer, directory, types)`
  - Extract: `write_table_sections(file_writer, directory, tables)`
  - Extract: `write_index_sections(file_writer, directory, indexes)`
  - Extract: `write_foreign_key_sections(file_writer, directory, foreign_keys)`
  - Extract: `write_view_sections(file_writer, directory, views)`
  - Extract: `write_function_sections(file_writer, directory, functions)`
  - Extract: `write_trigger_sections(file_writer, directory, triggers)`
  - Extract: `write_migrations_section(file_writer, directory)`
  - Result: Main method ~15 lines calling extracted methods

- [ ] **PostgresqlAdapter#fetch_custom_types - 39 lines**
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb:39-72`
  - Extract: `build_enum_type(row)` for enum processing
  - Extract: `build_composite_type(row)` for composite processing
  - Extract: `custom_types_query` for SQL string

- [ ] **SqliteAdapter#fetch_indexes - 61 lines**
  - File: `lib/better_structure_sql/adapters/sqlite_adapter.rb:122-161`
  - Extract: `parse_index_columns(table, index_name)`
  - Extract: `parse_where_clause(sql)` for partial index detection
  - Extract: `build_index_hash(table, name, unique, columns, where_clause)`

- [ ] **SqliteAdapter#fetch_triggers - 82 lines**
  - File: `lib/better_structure_sql/adapters/sqlite_adapter.rb:221-283`
  - Extract: `parse_trigger_timing(sql)` for BEFORE/AFTER detection
  - Extract: `parse_trigger_event(sql)` for INSERT/UPDATE/DELETE detection
  - Extract: `parse_for_each_row(sql)`
  - Extract: `parse_when_clause(sql)`
  - Extract: `extract_trigger_body(sql)`

- [ ] **Dumper#dump_single_file - 29 lines**
  - File: `lib/better_structure_sql/dumper.rb:43-69`
  - Extract: `build_section(title, items, generator_class)`
  - Use in loop to generate each section

- [ ] **TableGenerator#generate - 45+ lines**
  - File: `lib/better_structure_sql/generators/table_generator.rb:15-65`
  - Extract: `generate_columns_clause(table)`
  - Extract: `generate_constraints_clause(table)`
  - Extract: `generate_table_options(table)`

### SQL Query Extraction

- [ ] **Move long SQL queries to separate methods**
  - Pattern: queries over 10 lines should be in `def query_name` methods
  - PostgreSQL adapter: `custom_types_query`, `indexes_query`, `foreign_keys_query`
  - File: `lib/better_structure_sql/adapters/postgresql_adapter.rb`
  - MySQL adapter: Same pattern
  - File: `lib/better_structure_sql/adapters/mysql_adapter.rb`

### Error Handling Consistency

- [ ] **Standardize error messages across adapters**
  - Format: "[AdapterName] Feature description failed: #{error.message}"
  - Include database version in error context
  - File: `lib/better_structure_sql/adapters/*.rb` (all adapters)
  - Example: `rescue StandardError => e` blocks

- [ ] **Add custom exception classes**
  - File: `lib/better_structure_sql/errors.rb` (create new)
  - Classes: `AdapterError`, `IntrospectionError`, `GenerationError`, `ConfigurationError`
  - Replace generic `raise` with specific exceptions
  - Files: All adapters, dumper, configuration

- [ ] **Improve error messages in configuration validation**
  - File: `lib/better_structure_sql/configuration.rb:120-145`
  - Add suggestions for common mistakes
  - Example: "output_path must be absolute path or 'db/structure.sql'"

### Code Duplication Removal

- [ ] **Extract common adapter query patterns**
  - File: `lib/better_structure_sql/adapters/base_adapter.rb`
  - Method: `execute_query_with_fallback(query, fallback_value = [])`
  - Handles rescue, logging, graceful degradation
  - Use in all adapters

- [ ] **Extract common generator patterns**
  - File: `lib/better_structure_sql/generators/base.rb:15-30`
  - Method: `quote_identifier(name)` - check adapter type
  - Method: `format_sql_list(items)` - comma-separated with newlines
  - Method: `add_statement_terminator(sql)` - semicolon and newline

- [ ] **DRY up file writer directory creation**
  - File: `lib/better_structure_sql/file_writer.rb:85-140`
  - Repeated pattern: `FileUtils.mkdir_p(section_dir)` before each section
  - Extract: `ensure_section_directory(section_name)` method

### Documentation Improvements

- [ ] **Add YARD documentation to private methods**
  - Currently: Only public methods documented
  - Target: All methods over 5 lines need YARD comments
  - Files: All adapters, generators, dumper

- [ ] **Add code examples to YARD docs**
  - File: `lib/better_structure_sql/configuration.rb`
  - Show example configuration in class-level YARD comment
  - Files: All main classes

- [ ] **Document complex algorithms**
  - File: `lib/better_structure_sql/file_writer.rb:155-180` (chunking logic)
  - Add inline comments explaining overflow threshold calculation
  - File: `lib/better_structure_sql/manifest_generator.rb:25-45`
  - Explain load order dependency algorithm

### Test Coverage Improvements

- [ ] **Add edge case tests**
  - Empty database (0 tables, 0 objects)
  - Reserved SQL keywords in identifiers (table named "select", column named "where")
  - Unicode in identifiers (table "用户", column "名前")
  - Very long identifiers (PostgreSQL 63 char limit)
  - Circular view dependencies (view1 → view2 → view1)
  - File: `spec/integration/edge_cases_spec.rb` (create new)

- [ ] **Add property-based tests**
  - Gem: `rspec-quickcheck` or `propcheck`
  - Generate random schemas and verify dump/load round-trip
  - File: `spec/property/schema_roundtrip_spec.rb` (create new)

- [ ] **Improve test organization**
  - File: `spec/` (review structure)
  - Group adapter tests by feature (introspection, generation, edge cases)
  - Consistent naming: `*_adapter_spec.rb`, `*_generator_spec.rb`, `*_integration_spec.rb`

### Code Style Consistency

- [ ] **Run Rubocop and fix violations**
  - File: `.rubocop.yml` (ensure exists and configured)
  - Command: `rubocop -a` for auto-fixable issues
  - Target: 0 offenses
  - Add Rubocop to CI if not present

- [ ] **Standardize method ordering**
  - Pattern: public → protected → private (top to bottom)
  - Alphabetical within each section (optional)
  - Files: All classes

- [ ] **Consistent boolean method naming**
  - Pattern: `supports_*?`, `has_*?`, `is_*?`
  - Review all adapters for consistency
  - File: `lib/better_structure_sql/adapters/*.rb`

## Acceptance Criteria

✅ No methods over 20 lines (except queries)
✅ All SQL queries over 10 lines in dedicated methods
✅ Custom exception classes for all error types
✅ Error messages include context and suggestions
✅ Common patterns extracted to base classes
✅ All methods have YARD documentation
✅ Edge cases tested and passing
✅ Rubocop passes with 0 offenses

## Files to Modify

### Major Refactoring
- `lib/better_structure_sql/dumper.rb` - Extract methods (127 lines → ~15 lines)
- `lib/better_structure_sql/adapters/postgresql_adapter.rb` - Extract queries and helpers
- `lib/better_structure_sql/adapters/sqlite_adapter.rb` - Extract parsing methods
- `lib/better_structure_sql/generators/table_generator.rb` - Extract clause builders

### New Files
- `lib/better_structure_sql/errors.rb` - Custom exception classes
- `spec/integration/edge_cases_spec.rb` - Edge case tests
- `spec/property/schema_roundtrip_spec.rb` - Property-based tests

### Minor Updates
- `lib/better_structure_sql/adapters/base_adapter.rb` - Common query patterns
- `lib/better_structure_sql/generators/base.rb` - Common generator patterns
- `lib/better_structure_sql/file_writer.rb` - Extract directory helpers
- `lib/better_structure_sql/configuration.rb` - Improve error messages
- `.rubocop.yml` - Code style enforcement

## Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Avg method length | ~18 lines | 10 lines |
| Max method length | 127 lines | 20 lines |
| Methods > 20 lines | 12+ | 0 |
| Test coverage | 95% | 98% |
| Rubocop offenses | Unknown | 0 |
| YARD coverage | ~60% | 100% |
