# Multi-Database Adapter Architecture

## Core Components

### 1. Adapter Registry
**Location**: `lib/better_structure_sql/adapters/registry.rb`

**Responsibilities**:
- Register available adapters (postgresql, mysql, sqlite)
- Auto-detect adapter from ActiveRecord connection
- Validate adapter support
- Factory pattern for adapter instantiation
- Cache adapter instances per connection

**Interface**:
```ruby
BetterStructureSql::Adapters::Registry
  .register(:postgresql, PostgresqlAdapter)
  .register(:mysql, MysqlAdapter)
  .register(:sqlite, SqliteAdapter)
  .adapter_for(connection) # Auto-detect
  .adapter_for(connection, :mysql) # Explicit
```

**Dependencies**:
- ActiveRecord::Base.connection
- Configuration adapter override

### 2. Base Adapter
**Location**: `lib/better_structure_sql/adapters/base_adapter.rb`

**Responsibilities**:
- Define abstract interface (contract) for all adapters
- Provide default implementations for common operations
- Database version detection abstraction
- Feature capability detection
- Error handling patterns

**Abstract Methods** (must implement):
```ruby
class BaseAdapter
  # Introspection
  def fetch_extensions(connection)
  def fetch_types(connection)
  def fetch_tables(connection)
  def fetch_indexes(connection, table_name)
  def fetch_foreign_keys(connection)
  def fetch_views(connection)
  def fetch_functions(connection)
  def fetch_sequences(connection)
  def fetch_triggers(connection)

  # SQL Generation
  def generate_extension(extension)
  def generate_type(type)
  def generate_table(table)
  def generate_index(index)
  def generate_foreign_key(fk)
  def generate_view(view)
  def generate_function(function)
  def generate_trigger(trigger)

  # Capabilities
  def supports_extensions?
  def supports_materialized_views?
  def supports_stored_procedures?
  def supports_custom_types?
  def supports_domains?
  def supports_triggers?
  def supports_sequences?
  def supports_partitioning?

  # Version & Detection
  def database_version(connection)
  def version_supports?(feature, version)
  def adapter_name
end
```

**Concrete Methods** (shared implementation):
- Error logging with warnings
- Feature availability checks
- Version comparison logic
- Type normalization helpers

**Dependencies**:
- ActiveRecord connection object
- Configuration object

### 3. PostgreSQL Adapter
**Location**: `lib/better_structure_sql/adapters/postgresql_adapter.rb`

**Responsibilities**:
- Migrate existing PostgreSQL-specific logic
- Query pg_catalog and information_schema
- Generate PostgreSQL SQL syntax
- Support all advanced features (extensions, types, functions, triggers)
- Maintain backward compatibility

**PostgreSQL-Specific Queries**:
- `pg_extension`, `pg_namespace` - Extensions
- `pg_type`, `pg_enum`, `pg_attribute` - Custom types
- `pg_proc`, `pg_language` - Functions
- `pg_trigger` - Triggers
- `pg_sequences` - Sequences
- `pg_matviews` - Materialized views
- `pg_get_functiondef()` - Function DDL
- `pg_get_triggerdef()` - Trigger DDL
- `pg_get_constraintdef()` - Constraint DDL

**Feature Support**: All features enabled

**Dependencies**:
- `pg` gem (runtime)
- PostgreSQL 10+ (minimum version)

### 4. MySQL Adapter
**Location**: `lib/better_structure_sql/adapters/mysql_adapter.rb`

**Responsibilities**:
- Query information_schema (MySQL variant)
- Query mysql.* system tables
- Generate MySQL SQL syntax
- Map PostgreSQL features to MySQL equivalents
- Handle MySQL version differences (5.7 vs 8.0+)

**MySQL-Specific Queries**:
- `information_schema.TABLES` - Tables
- `information_schema.COLUMNS` - Columns
- `information_schema.STATISTICS` - Indexes
- `information_schema.TABLE_CONSTRAINTS` - Constraints
- `information_schema.REFERENTIAL_CONSTRAINTS` - Foreign keys
- `information_schema.VIEWS` - Views
- `information_schema.ROUTINES` - Stored procedures
- `information_schema.TRIGGERS` - Triggers
- `SHOW CREATE TABLE` - Full table DDL
- `SHOW CREATE PROCEDURE` - Procedure DDL
- `SHOW CREATE TRIGGER` - Trigger DDL

**Feature Support**:
- Extensions: No (feature disabled)
- Materialized Views: No (feature disabled)
- Custom Types: Partial (ENUM as SET, no composite types)
- Domains: No (feature disabled)
- Functions: Yes (stored procedures)
- Triggers: Yes
- Sequences: No (uses AUTO_INCREMENT)
- Partitioning: Yes (MySQL 8.0+)

**Type Mappings**:
- PostgreSQL ENUM → MySQL SET or ENUM
- PostgreSQL ARRAY → MySQL JSON
- PostgreSQL composite type → MySQL JSON
- PostgreSQL domain → Inline constraint
- PostgreSQL SERIAL → MySQL AUTO_INCREMENT
- PostgreSQL BIGSERIAL → MySQL BIGINT AUTO_INCREMENT

**Dependencies**:
- `mysql2` gem (runtime)
- MySQL 8.0+ (recommended, 5.7 partial support)

### 5. SQLite Adapter
**Location**: `lib/better_structure_sql/adapters/sqlite_adapter.rb`

**Responsibilities**:
- Query sqlite_master system table
- Query PRAGMA statements for metadata
- Generate SQLite SQL syntax
- Handle SQLite limitations gracefully
- Minimal feature set

**SQLite-Specific Queries**:
- `sqlite_master` - All objects (tables, indexes, triggers, views)
- `PRAGMA table_info(table_name)` - Column metadata
- `PRAGMA foreign_key_list(table_name)` - Foreign keys
- `PRAGMA index_list(table_name)` - Index list
- `PRAGMA index_info(index_name)` - Index columns

**Feature Support**:
- Extensions: No
- Materialized Views: No
- Custom Types: No
- Domains: No
- Functions: No (SQL functions only, no stored procedures)
- Triggers: Yes (limited - no plpgsql)
- Sequences: No (uses AUTOINCREMENT)
- Partitioning: No
- Views: Yes

**Type Mappings**:
- PostgreSQL types → SQLite affinities (TEXT, NUMERIC, INTEGER, REAL, BLOB)
- All constraints inline with table definition
- No separate ALTER TABLE for foreign keys

**Dependencies**:
- `sqlite3` gem (runtime)
- SQLite 3.35+ (recommended)

### 6. Introspection Modules (Refactored)
**Location**: `lib/better_structure_sql/introspection/*.rb`

**Current State**: Mixin modules with PostgreSQL-specific queries
**Future State**: Thin delegation layer to adapter

**Before (PostgreSQL-only)**:
```ruby
module BetterStructureSql::Introspection::Extensions
  def fetch_extensions(connection)
    # Direct pg_extension query
  end
end
```

**After (Adapter-delegated)**:
```ruby
module BetterStructureSql::Introspection::Extensions
  def fetch_extensions(connection)
    adapter = BetterStructureSql::Adapters::Registry.adapter_for(connection)
    adapter.fetch_extensions(connection)
  end
end
```

**Responsibilities**:
- Delegate to appropriate adapter
- Cache adapter instance
- Maintain backward-compatible interface
- Handle adapter errors gracefully

**Migration Strategy**: Incremental refactoring per module

### 7. Generators (Refactored)
**Location**: `lib/better_structure_sql/generators/*.rb`

**Current State**: PostgreSQL SQL syntax hardcoded
**Future State**: Delegate to adapter for SQL generation

**Before (PostgreSQL-only)**:
```ruby
class ExtensionGenerator
  def generate(extension)
    "CREATE EXTENSION IF NOT EXISTS #{extension[:name]};"
  end
end
```

**After (Adapter-aware)**:
```ruby
class ExtensionGenerator
  def generate(extension, adapter)
    adapter.generate_extension(extension)
  end
end
```

**Adapter-Specific Generation**:
- PostgreSQL: `CREATE EXTENSION IF NOT EXISTS`
- MySQL: Feature not supported (no-op)
- SQLite: Feature not supported (no-op)

**Responsibilities**:
- Invoke adapter-specific SQL generation
- Format output consistently
- Handle feature unavailability
- Maintain generator interface for Dumper

### 8. Dumper (Adapter-Aware Orchestration)
**Location**: `lib/better_structure_sql/dumper.rb`

**Current Behavior**: Hardcoded PostgreSQL assumptions
**Future Behavior**: Adapter-driven orchestration

**Changes Required**:
1. Detect adapter at initialization
2. Pass adapter to introspection methods
3. Pass adapter to generators
4. Skip unsupported features based on adapter capabilities
5. Adjust section ordering per adapter

**Orchestration Flow**:
```ruby
class Dumper
  def initialize(connection)
    @connection = connection
    @adapter = Registry.adapter_for(connection)
  end

  def dump
    sections = []
    sections << dump_extensions if @adapter.supports_extensions?
    sections << dump_types if @adapter.supports_custom_types?
    sections << dump_sequences if @adapter.supports_sequences?
    sections << dump_tables
    sections << dump_indexes
    sections << dump_foreign_keys
    sections << dump_views
    sections << dump_materialized_views if @adapter.supports_materialized_views?
    sections << dump_functions if @adapter.supports_stored_procedures?
    sections << dump_triggers if @adapter.supports_triggers?
    sections.compact.join("\n\n")
  end
end
```

**Dependencies**:
- Adapter registry
- Introspection modules
- Generators
- Configuration

### 9. Configuration (Adapter Settings)
**Location**: `lib/better_structure_sql/configuration.rb`

**New Settings**:
```ruby
class Configuration
  attr_accessor :adapter # :auto, :postgresql, :mysql, :sqlite

  # Adapter-specific configurations
  attr_accessor :postgresql_config
  attr_accessor :mysql_config
  attr_accessor :sqlite_config

  def postgresql
    @postgresql_config ||= PostgresqlConfig.new
  end

  def mysql
    @mysql_config ||= MysqlConfig.new
  end

  def sqlite
    @sqlite_config ||= SqliteConfig.new
  end
end

class PostgresqlConfig
  attr_accessor :include_extensions, :include_functions, :include_triggers
  # ... existing PostgreSQL settings
end

class MysqlConfig
  attr_accessor :include_stored_procedures, :include_triggers
  attr_accessor :use_show_create # Use SHOW CREATE vs manual DDL
end

class SqliteConfig
  attr_accessor :include_triggers
  # Minimal settings
end
```

**Responsibilities**:
- Store adapter override
- Provide adapter-specific feature toggles
- Validate configuration per adapter
- Provide defaults per adapter

### 10. Schema Versions (Adapter-Agnostic Storage)
**Location**: `lib/better_structure_sql/schema_versions.rb`

**Current Implementation**: Works with PostgreSQL
**Required Changes**: Minimal (already adapter-agnostic)

**Table Structure** (already compatible):
```sql
CREATE TABLE better_structure_sql_schema_versions (
  id BIGINT PRIMARY KEY,
  content TEXT,
  zip_archive BLOB/BYTEA,
  pg_version VARCHAR, -- Rename to db_version
  format_type VARCHAR, -- sql/rb
  output_mode VARCHAR, -- single_file/multi_file
  created_at TIMESTAMP
);
```

**Changes**:
- Rename `pg_version` column to `db_version`
- Add `db_adapter` column (postgresql, mysql, sqlite)
- Store adapter-specific version strings
- Migration for existing data

**Responsibilities**:
- Store schema versions for any adapter
- Track database type and version
- Support cross-database comparisons
- ZIP storage compatible with all adapters

## Component Interactions

### Dump Flow
```
User calls: db:schema:dump
  ↓
Rake Task → Dumper.new(connection)
  ↓
Dumper → Registry.adapter_for(connection)
  ↓
Registry → PostgresqlAdapter.new / MysqlAdapter.new / SqliteAdapter.new
  ↓
Dumper → Introspection.fetch_tables(connection)
  ↓
Introspection → adapter.fetch_tables(connection)
  ↓
Adapter → Execute database-specific query → Returns normalized data
  ↓
Dumper → Generator.generate(table, adapter)
  ↓
Generator → adapter.generate_table(table) → Returns SQL string
  ↓
Dumper → FileWriter.write(sections)
  ↓
FileWriter → Write to structure.sql or db/schema/ directory
```

### Adapter Selection Flow
```
1. Configuration check: config.adapter present?
   YES → Use configured adapter
   NO → Continue to auto-detect

2. ActiveRecord connection check
   connection.adapter_name → "PostgreSQL" / "Mysql2" / "SQLite"
   ↓
   Registry lookup → PostgresqlAdapter / MysqlAdapter / SqliteAdapter

3. Adapter instantiation
   adapter = AdapterClass.new(config.adapter_config)

4. Feature detection
   adapter.supports_extensions? → true/false
   adapter.database_version(connection) → "15.2" / "8.0.32" / "3.42.0"

5. Cache adapter instance (per dump session)
```

## Data Flow Patterns

### Normalized Data Structures
Adapters return standardized hashes regardless of source database:

**Table Structure**:
```ruby
{
  name: "users",
  schema: "public",
  columns: [
    {name: "id", type: "bigint", nullable: false, default: nil},
    {name: "email", type: "varchar", length: 255, nullable: false}
  ],
  primary_key: ["id"],
  check_constraints: [...],
  unique_constraints: [...]
}
```

**Index Structure**:
```ruby
{
  name: "index_users_on_email",
  table: "users",
  columns: ["email"],
  unique: true,
  type: "btree", # or "hash", "gin", etc.
  where: "deleted_at IS NULL" # partial index
}
```

**Foreign Key Structure**:
```ruby
{
  name: "fk_posts_user_id",
  table: "posts",
  columns: ["user_id"],
  referenced_table: "users",
  referenced_columns: ["id"],
  on_delete: "CASCADE",
  on_update: "RESTRICT"
}
```

### Type Mapping Strategy
Each adapter provides canonical type mapping:

**PostgreSQL → Canonical**:
- `character varying` → `varchar`
- `timestamp without time zone` → `timestamp`
- `timestamp with time zone` → `timestamptz`
- `integer` → `integer`
- `bigint` → `bigint`

**MySQL → Canonical**:
- `VARCHAR` → `varchar`
- `DATETIME` → `timestamp`
- `INT` → `integer`
- `BIGINT` → `bigint`
- `TINYINT(1)` → `boolean`

**SQLite → Canonical**:
- `TEXT` → `varchar`
- `INTEGER` → `integer`
- `REAL` → `float`
- `BLOB` → `bytea`

## Error Handling Patterns

### Unsupported Feature Requests
```ruby
class MysqlAdapter < BaseAdapter
  def fetch_extensions(connection)
    log_warning("Extensions not supported on MySQL")
    []
  end

  def supports_extensions?
    false
  end
end
```

### Version-Specific Feature Detection
```ruby
class MysqlAdapter < BaseAdapter
  def supports_check_constraints?
    database_version >= Gem::Version.new('8.0.16')
  end

  def fetch_check_constraints(connection)
    return [] unless supports_check_constraints?
    # Query implementation
  end
end
```

### Graceful Degradation
```ruby
class Dumper
  def dump_extensions
    return nil unless adapter.supports_extensions?

    extensions = introspection.fetch_extensions(connection)
    return nil if extensions.empty?

    extensions.map { |ext| generator.generate(ext, adapter) }.join("\n")
  rescue AdapterError => e
    log_error("Failed to dump extensions: #{e.message}")
    nil
  end
end
```

## Dependencies Graph

```
Registry
  → BaseAdapter (abstract)
    → PostgresqlAdapter (requires: pg gem)
    → MysqlAdapter (requires: mysql2 gem)
    → SqliteAdapter (requires: sqlite3 gem)

Configuration
  → PostgresqlConfig
  → MysqlConfig
  → SqliteConfig

Dumper
  → Registry (adapter detection)
  → Introspection (delegates to adapter)
  → Generators (adapter-aware SQL generation)
  → FileWriter (adapter-agnostic)
  → Configuration (adapter settings)

Introspection
  → Registry (adapter lookup)
  → Adapter methods (fetch_*)

Generators
  → Adapter methods (generate_*)
  → Formatter (adapter-agnostic)

SchemaVersions
  → ActiveRecord (adapter-agnostic ORM)
  → Configuration (versioning settings)

SchemaLoader
  → ManifestGenerator (adapter-agnostic)
  → ZipGenerator (adapter-agnostic)
```

## Testing Architecture

### Unit Tests (Per Adapter)
- `spec/adapters/postgresql_adapter_spec.rb`
- `spec/adapters/mysql_adapter_spec.rb`
- `spec/adapters/sqlite_adapter_spec.rb`
- Test introspection queries return normalized data
- Test SQL generation produces valid syntax
- Test feature detection accuracy
- Mock database connections

### Integration Tests (Per Database)
- `integration_postgresql/` - PostgreSQL integration app
- `integration_mysql/` - MySQL integration app
- `integration_sqlite/` - SQLite integration app
- Full dump workflow tests
- Schema load tests
- Version storage tests
- Real database connections

### Cross-Adapter Tests
- Schema comparison across databases
- Feature parity validation
- Performance benchmarks
- Migration compatibility

## Performance Considerations

### Query Optimization
- Batch metadata queries where possible
- Database-specific index usage
- Minimize roundtrips (single query for all tables)
- Cache introspection results per dump session

### Memory Management
- Stream large result sets
- Multi-file chunking for massive schemas
- Avoid loading entire schema into memory
- Efficient data structure conversion

### Adapter Caching
- Cache adapter instance per connection
- Cache database version detection
- Cache feature support checks
- Clear cache on configuration change

## Migration Strategy

### Phase 1: Adapter Infrastructure
- Create adapter base class and registry
- Migrate PostgreSQL code to adapter
- Add adapter detection logic
- Update configuration for adapter settings
- No breaking changes (PostgreSQL still works)

### Phase 2: MySQL Support
- Implement MySQL adapter
- Create integration_mysql app
- MySQL-specific tests
- Documentation for MySQL users

### Phase 3: SQLite Support
- Implement SQLite adapter
- Create integration_sqlite app
- SQLite-specific tests
- Documentation for SQLite users

### Phase 4: Gemspec Optimization
- Remove hard dependency on pg gem
- Document conditional gem installation
- Update README with multi-database instructions

## Keywords

Adapter registry, adapter factory pattern, adapter instantiation, adapter caching, base adapter abstract class, adapter interface contract, adapter detection auto-detect, ActiveRecord connection adapter_name, PostgreSQL adapter implementation, MySQL adapter implementation, SQLite adapter implementation, adapter-specific queries, pg_catalog queries, information_schema queries, mysql system tables, sqlite_master queries, PRAGMA statements, introspection abstraction, SQL generation delegation, feature capability detection, database version detection, version-aware features, supports_extensions, supports_materialized_views, supports_stored_procedures, supports_custom_types, supports_triggers, supports_sequences, normalized data structures, canonical type mapping, type affinity SQLite, PostgreSQL to MySQL type mapping, ENUM to SET mapping, composite type to JSON, array to JSON, sequence to AUTO_INCREMENT, graceful feature degradation, unsupported feature handling, version-specific features, MySQL 8.0 check constraints, error handling patterns, adapter error logging, configuration per adapter, PostgresqlConfig, MysqlConfig, SqliteConfig, adapter-specific settings, feature toggles per database, dumper orchestration adapter-aware, generator adapter delegation, introspection adapter delegation, schema versions adapter-agnostic, db_version column, db_adapter column, cross-database schema storage, component interaction flow, dump workflow, adapter selection flow, dependency injection, connection passing, query optimization per adapter, batch metadata queries, memory efficient streaming, adapter instance caching, integration testing per database, unit testing per adapter, cross-adapter testing, feature parity validation, migration strategy phases, backward compatibility PostgreSQL, zero breaking changes, conditional gem dependencies, gemspec optional dependencies
