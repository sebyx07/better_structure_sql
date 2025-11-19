# MVP Implementation Phases

Implementation roadmap for BetterStructureSql gem development.

## Overview

Three-phase development approach:

1. **Phase 1**: Core schema dumping foundation
2. **Phase 2**: Schema versioning system
3. **Phase 3**: Advanced PostgreSQL features

## Phase Summary

### Phase 1: Core Schema Dumping ⚡

**Goal**: Clean structure.sql generation without pg_dump

**Duration**: 2-3 weeks

**Key Deliverables**:
- Pure Ruby PostgreSQL introspection
- Table, index, foreign key generation
- Extension and custom type support
- Rails integration (rake tasks)
- Basic testing framework

**Files**: ~20 Ruby files, ~25 spec files

[Full Phase 1 Details →](phase-1.md)

### Phase 2: Schema Versioning 💾

**Goal**: Database-backed schema version storage

**Duration**: 1-2 weeks

**Key Deliverables**:
- SchemaVersion ActiveRecord model
- Version storage and retrieval
- Retention policy management
- PostgreSQL version tracking
- API endpoint examples

**Files**: ~8 Ruby files, ~10 spec files

[Full Phase 2 Details →](phase-2.md)

### Phase 3: Advanced Features 🔧

**Goal**: Complete PostgreSQL feature support

**Duration**: 3-4 weeks

**Key Deliverables**:
- Views and materialized views
- Functions and triggers
- Partitioned tables
- Table inheritance
- Dependency resolution
- Performance optimization

**Files**: ~15 Ruby files, ~20 spec files

[Full Phase 3 Details →](phase-3.md)

## Total Effort Estimate

- **Development**: 6-9 weeks
- **Testing**: Ongoing throughout all phases
- **Documentation**: Ongoing throughout all phases

## Success Criteria

### Phase 1 Complete When:
- [ ] Generates clean structure.sql for basic schemas
- [ ] All unit tests passing
- [ ] Integration tests with dummy app
- [ ] Output comparable to pg_dump (tables, indexes, FKs)
- [ ] Rails 7+ integration working

### Phase 2 Complete When:
- [ ] Schema versions stored in database
- [ ] Retention policy functional
- [ ] Version retrieval working
- [ ] All versioning tests passing
- [ ] API endpoint documented

### Phase 3 Complete When:
- [ ] All PostgreSQL features supported
- [ ] Complex dummy app schema fully dumped
- [ ] Performance meets targets
- [ ] Comparison tests vs pg_dump passing
- [ ] Documentation complete

## Development Workflow

### Per Phase

1. **Planning**
   - Review phase tasks
   - Identify dependencies
   - Setup development branch

2. **Implementation**
   - TDD approach (test first)
   - Incremental feature development
   - Regular commits

3. **Testing**
   - Unit tests for each component
   - Integration tests for features
   - Manual testing with dummy app

4. **Documentation**
   - Inline code docs (YARD)
   - User-facing docs
   - Examples and guides

5. **Review**
   - Code review
   - Performance check
   - Documentation review

## Testing Strategy

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast execution (<1s per test)

### Integration Tests
- Test full workflow
- Use dummy Rails app
- Compare with pg_dump output
- Test edge cases

### Performance Tests
- Benchmark against pg_dump
- Test with varying database sizes
- Monitor memory usage

### Comparison Tests
- Generate schema with both tools
- Normalize and compare output
- Ensure completeness

## Dummy App Requirements

Complex schema including:
- 15+ tables with relationships
- 5+ PostgreSQL extensions
- Custom types and enums
- Multiple index types (partial, expression, multi-column)
- Views and materialized views
- Functions (plpgsql)
- Triggers
- Partitioned tables
- Foreign keys with various actions

See [spec/dummy/README.md](../../spec/dummy/README.md) for full schema.

## Technology Stack

- **Language**: Ruby 2.7+
- **Framework**: Rails 7.0+
- **Database**: PostgreSQL 12+
- **Testing**: RSpec 3.x
- **CI**: GitHub Actions
- **Coverage**: SimpleCov
- **Linting**: Rubocop

## Dependencies

### Runtime
- `rails >= 7.0`
- `pg >= 1.0`

### Development
- `rspec-rails`
- `factory_bot_rails`
- `faker`
- `database_cleaner`
- `simplecov`
- `rubocop`
- `rubocop-rails`
- `rubocop-rspec`

## Milestones

### M1: Foundation (Phase 1)
- Core introspection working
- Basic SQL generation
- Rails integration

### M2: Versioning (Phase 2)
- Schema storage functional
- Retention working
- API documented

### M3: Complete (Phase 3)
- All features implemented
- Performance optimized
- Ready for v1.0.0 release

## Risk Mitigation

### Technical Risks

**PostgreSQL Version Compatibility**
- Risk: Different PG versions have different metadata schemas
- Mitigation: Test against PG 12, 13, 14, 15, 16
- Fallback: Document minimum supported version

**Performance with Large Schemas**
- Risk: Slow with 500+ tables
- Mitigation: Implement caching, batch queries, parallel processing
- Fallback: Document performance expectations

**pg_dump Parity**
- Risk: Missing edge cases
- Mitigation: Comprehensive comparison tests
- Fallback: Document known differences

### Project Risks

**Scope Creep**
- Risk: Adding too many features
- Mitigation: Stick to phase plan, defer non-essentials
- Fallback: Cut Phase 3 features to optional

**Testing Coverage**
- Risk: Insufficient test coverage
- Mitigation: Enforce >95% coverage, mandatory integration tests
- Fallback: Focus on critical path coverage

## Release Plan

### v0.1.0 - Phase 1 Complete
- Basic functionality
- Alpha testing with select users

### v0.2.0 - Phase 2 Complete
- Schema versioning
- Beta release

### v1.0.0 - Phase 3 Complete
- All features
- Production ready
- Public announcement

## Support Plan

### Documentation
- Comprehensive README
- Per-feature docs
- API documentation (YARD)
- Examples and guides

### Issue Management
- GitHub Issues
- Bug reports template
- Feature requests template
- Response within 48 hours

### Community
- Contributing guidelines
- Code of conduct
- Changelog maintenance
