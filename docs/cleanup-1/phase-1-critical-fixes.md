# Phase 1: Critical Fixes (Pre-v1.0)

**Priority**: HIGH
**Estimated Effort**: 2-3 days
**Goal**: Fix misleading documentation and unused code before v1.0 release

## Todo List

### Documentation Accuracy

- [ ] **Remove unimplemented feature claims from README.md**
  - Remove "✅ Partitioned Tables (RANGE/LIST/HASH)" from PostgreSQL features
  - Remove "✅ Table Inheritance" if present
  - Or add "🚧 Planned" prefix for future features
  - File: `README.md` (feature matrix section)

- [ ] **Update CLAUDE.md to reflect actual implementation**
  - Line ~80: Remove "Partitioned tables (RANGE, LIST, HASH)" from Advanced section
  - Line ~81: Remove "Table inheritance" from Advanced section
  - Line ~82: Remove "Comments on database objects" from Advanced section
  - Or move to "Planned Features" section
  - File: `CLAUDE.md`

- [ ] **Document DependencyResolver status**
  - Add note that DependencyResolver exists but is not currently integrated
  - Current ordering uses fixed section order (extensions → types → tables → etc.)
  - Explain why this works for most cases but may fail for complex view dependencies
  - File: `docs/architecture/dependency-resolution.md` (create if missing)

- [ ] **Remove unused configuration options or document as experimental**
  - `include_comments` - toggle exists but does nothing (line 24 in `lib/better_structure_sql/configuration.rb`)
  - `include_rules` - toggle exists but does nothing (line 27)
  - Either remove or add "Not yet implemented" warning in initializer template
  - File: `lib/better_structure_sql/configuration.rb`
  - File: `lib/generators/better_structure_sql/templates/initializer.rb`

### Code Cleanup

- [ ] **Remove or integrate DependencyResolver**
  - Option A: Remove class entirely if not using
  - Option B: Integrate into Dumper for view/function ordering
  - File: `lib/better_structure_sql/dependency_resolver.rb` (64 lines)
  - File: `lib/better_structure_sql/dumper.rb` (integration point)
  - Decision: Remove for now, implement properly in Phase 3

- [ ] **Add TODO comments for unimplemented features**
  - If keeping config toggles, add TODO comments explaining not implemented
  - File: `lib/better_structure_sql/configuration.rb:24,27`

- [ ] **Update GitHub Pages documentation site**
  - Remove partitioned tables tutorial if not implemented
  - Remove table inheritance examples
  - Add "Roadmap" page for planned features
  - Directory: `site/src/content/`

### Testing

- [ ] **Add test warnings for unimplemented features**
  - Skip tests for partitioned tables with "Not yet implemented" message
  - Skip tests for table inheritance
  - File: `spec/` (review integration tests)

- [ ] **Verify no integration migrations test unimplemented features**
  - Check `integration/db/migrate/` - ensure no partitioned table migrations
  - Check for inherited tables
  - If found, comment out or remove

## Acceptance Criteria

✅ No documentation claims features that don't exist
✅ Unused code removed or marked with TODO comments
✅ Users understand current capabilities and limitations
✅ No failing tests due to unimplemented features
✅ Configuration options documented as experimental if non-functional

## Files to Modify

- `README.md` - Feature matrix
- `CLAUDE.md` - Architecture documentation
- `lib/better_structure_sql/configuration.rb` - Config options
- `lib/generators/better_structure_sql/templates/initializer.rb` - Template
- `lib/better_structure_sql/dependency_resolver.rb` - Remove or integrate
- `lib/better_structure_sql/dumper.rb` - If integrating resolver
- `docs/architecture/dependency-resolution.md` - Create new doc
- `site/src/content/*.md` - GitHub Pages content
