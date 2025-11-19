# Phase 1: Core Schema Dumping

Foundation implementation for clean PostgreSQL schema dumps without pg_dump.

## Objectives

- Pure Ruby schema introspection
- Clean structure.sql output
- Basic PostgreSQL object support
- Rails task integration

## Tasks

### 1. Project Setup

- [ ] Create gem skeleton with bundler
- [ ] Setup RSpec testing framework
- [ ] Configure Rubocop for code quality
- [ ] Create dummy Rails 7+ app for testing
- [ ] Setup PostgreSQL test database

### 2. Configuration System

**File**: `lib/better_structure_sql/configuration.rb`

- [ ] Create Configuration class with defaults
- [ ] Implement configure block pattern
- [ ] Add configuration options:
  - `output_path` (default: 'db/structure.sql')
  - `search_path` (default: '"$user", public')
  - `replace_default_dump` (default: false)
  - `include_extensions` (default: true)
  - `include_functions` (default: true)
  - `include_triggers` (default: true)
  - `include_views` (default: true)
  - `include_sequences` (default: true)
  - `include_custom_types` (default: true)
- [ ] Add configuration validation
- [ ] Write configuration specs

### 3. Database Introspection

**File**: `lib/better_structure_sql/introspection.rb`

Query `information_schema` and `pg_catalog` for schema objects.

- [ ] Implement `fetch_extensions` using pg_extension
- [ ] Implement `fetch_custom_types` using pg_type
- [ ] Implement `fetch_enums` using pg_enum
- [ ] Implement `fetch_sequences` using pg_sequences
- [ ] Implement `fetch_tables` with columns using information_schema.tables
- [ ] Implement `fetch_primary_keys` using pg_constraint
- [ ] Implement `fetch_foreign_keys` using pg_constraint
- [ ] Implement `fetch_indexes` using pg_indexes
- [ ] Implement `fetch_check_constraints` using pg_constraint
- [ ] Implement `fetch_unique_constraints` using pg_constraint
- [ ] Write introspection specs

### 4. SQL Generation

**File**: `lib/better_structure_sql/generators/`

- [ ] Create `ExtensionGenerator` for CREATE EXTENSION
- [ ] Create `TypeGenerator` for CREATE TYPE
- [ ] Create `SequenceGenerator` for CREATE SEQUENCE
- [ ] Create `TableGenerator` for CREATE TABLE with:
  - Column definitions
  - Column defaults
  - NOT NULL constraints
  - Primary keys
- [ ] Create `IndexGenerator` for CREATE INDEX:
  - Regular indexes
  - Unique indexes
  - Partial indexes
  - Expression indexes
  - Multi-column indexes
- [ ] Create `ForeignKeyGenerator` for ALTER TABLE ADD CONSTRAINT
- [ ] Create `CheckConstraintGenerator` for CHECK constraints
- [ ] Write generator specs for each type

### 5. Main Dumper

**File**: `lib/better_structure_sql/dumper.rb`

- [ ] Create Dumper class
- [ ] Implement `dump` method with file writing
- [ ] Implement `dump_to_string` method
- [ ] Add proper ordering:
  1. SET client_encoding = 'UTF8'
  2. Extensions
  3. Custom types/enums
  4. Sequences
  5. Tables with columns
  6. Indexes
  7. Foreign keys
  8. Schema migrations INSERT
  9. SET search_path
  10. Footer comment
- [ ] Add section comments (-- Extensions, -- Tables, etc.)
- [ ] Write dumper integration specs

### 6. Schema Migrations Support

**File**: `lib/better_structure_sql/schema_migrations.rb`

- [ ] Query `schema_migrations` table
- [ ] Generate INSERT statements for versions
- [ ] Sort versions chronologically
- [ ] Handle missing schema_migrations table gracefully
- [ ] Write schema migrations specs

### 7. Rails Integration

**File**: `lib/better_structure_sql/railtie.rb`

- [ ] Create Railtie for Rails integration
- [ ] Add `db:schema:dump_better` rake task
- [ ] Conditionally override `db:schema:dump` when configured
- [ ] Add generator for installation:
  - `rails generate better_structure_sql:install`
  - Creates initializer file
- [ ] Write Rails integration specs

### 8. Formatting & Output

**File**: `lib/better_structure_sql/formatter.rb`

- [ ] Implement consistent indentation
- [ ] Implement SQL keyword capitalization
- [ ] Add section spacing
- [ ] Sort tables alphabetically
- [ ] Sort indexes alphabetically
- [ ] Write formatter specs

### 9. Error Handling

- [ ] Handle database connection errors
- [ ] Handle missing tables gracefully
- [ ] Handle permission errors with helpful messages
- [ ] Add logging for debugging
- [ ] Write error handling specs

### 10. Testing

**Specs**: `spec/`

- [ ] Unit tests for introspection
- [ ] Unit tests for generators
- [ ] Integration tests with dummy app
- [ ] Test output comparison with pg_dump
- [ ] Test edge cases:
  - Empty database
  - No schema_migrations
  - Complex column types (arrays, json, hstore)
  - Multi-column indexes
  - Partial indexes
  - Expression indexes
- [ ] Setup CI configuration (GitHub Actions)

### 11. Documentation

- [ ] Add inline code documentation (YARD)
- [ ] Create README examples
- [ ] Add usage examples to docs/
- [ ] Document supported PostgreSQL versions
- [ ] Document supported Rails versions

## Acceptance Criteria

- [ ] Generates clean structure.sql without pg_dump noise
- [ ] Supports all basic PostgreSQL objects (tables, indexes, foreign keys)
- [ ] Output is deterministic (same input = same output)
- [ ] Passes all RSpec tests
- [ ] Works with complex dummy app schema
- [ ] Compatible with Rails 7.0+
- [ ] Compatible with PostgreSQL 12+

## Files to Create

```
lib/
  better_structure_sql.rb
  better_structure_sql/
    configuration.rb
    dumper.rb
    formatter.rb
    introspection.rb
    railtie.rb
    schema_migrations.rb
    version.rb
    generators/
      extension_generator.rb
      type_generator.rb
      sequence_generator.rb
      table_generator.rb
      index_generator.rb
      foreign_key_generator.rb
      check_constraint_generator.rb

spec/
  spec_helper.rb
  better_structure_sql/
    configuration_spec.rb
    dumper_spec.rb
    formatter_spec.rb
    introspection_spec.rb
    schema_migrations_spec.rb
    generators/
      extension_generator_spec.rb
      type_generator_spec.rb
      table_generator_spec.rb
      index_generator_spec.rb
      foreign_key_generator_spec.rb
  integration/
    dumper_integration_spec.rb
    rails_integration_spec.rb
```

## Testing Strategy

Use dummy app with complex schema including:
- Multiple extensions (pgcrypto, uuid-ossp, pg_trgm)
- Custom types and enums
- Tables with various column types
- Complex indexes (partial, expression, multi-column)
- Foreign keys with ON DELETE/UPDATE actions
- Check constraints
- Default values (including functions)

## Next Phase

After Phase 1 completion, proceed to Phase 2: Schema Versioning.
