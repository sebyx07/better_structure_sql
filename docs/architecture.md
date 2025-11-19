# Architecture

Technical architecture and design patterns for BetterStructureSql.

## Design Principles

### Single Responsibility
Each class handles one specific concern:
- `Introspection` - Query database metadata
- `Generators` - Create SQL statements
- `Dumper` - Orchestrate dump process
- `Formatter` - Format output

### Pure Ruby
No external command dependencies. Database introspection via:
- `information_schema` tables
- `pg_catalog` tables
- ActiveRecord connection

### Deterministic Output
Same database state produces identical output:
- Sorted tables alphabetically
- Sorted indexes alphabetically
- Consistent formatting
- No timestamps or version comments

### Extensible
Easy to add new PostgreSQL features:
- Generator pattern for objects
- Plugin-friendly configuration
- Modular design

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Rails Application                 │
└─────────────────────────────────────────────────────┘
                        │
                        │ Rake Task / API
                        ▼
┌─────────────────────────────────────────────────────┐
│                      Dumper                         │
│  - Orchestrates dump process                        │
│  - Manages output file                              │
│  - Handles errors                                   │
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│Introspection│  │  Formatter  │  │SchemaVersion│
│- Query DB   │  │- Format SQL │  │- Store/Load │
│- Metadata   │  │- Indent     │  │- Cleanup    │
└─────────────┘  └─────────────┘  └─────────────┘
        │
        │ Database Objects
        ▼
┌─────────────────────────────────────────────────────┐
│                   Generators                        │
│  - ExtensionGenerator                               │
│  - TypeGenerator                                    │
│  - TableGenerator                                   │
│  - IndexGenerator                                   │
│  - ForeignKeyGenerator                              │
│  - ViewGenerator                                    │
│  - FunctionGenerator                                │
│  - TriggerGenerator                                 │
└─────────────────────────────────────────────────────┘
        │
        │ SQL Statements
        ▼
┌─────────────────────────────────────────────────────┐
│                  structure.sql                      │
└─────────────────────────────────────────────────────┘
```

## Core Components

### Configuration

**File**: `lib/better_structure_sql/configuration.rb`

**Responsibility**: Store and validate configuration

```ruby
class Configuration
  attr_accessor :output_path, :replace_default_dump,
                :enable_schema_versions, :schema_versions_limit,
                :include_extensions, :include_functions,
                :include_triggers, :include_views

  def initialize
    set_defaults
  end

  def validate!
    # Validation logic
  end
end
```

### Introspection

**File**: `lib/better_structure_sql/introspection.rb`

**Responsibility**: Query PostgreSQL metadata

**Methods**:
- `fetch_extensions` - Query pg_extension
- `fetch_custom_types` - Query pg_type for enums/domains
- `fetch_tables` - Query information_schema.tables
- `fetch_columns(table)` - Query information_schema.columns
- `fetch_indexes` - Query pg_indexes
- `fetch_foreign_keys` - Query pg_constraint
- `fetch_views` - Query pg_views
- `fetch_functions` - Query pg_proc
- `fetch_triggers` - Query pg_trigger

**Implementation**:
```ruby
class Introspection
  def initialize(connection = ActiveRecord::Base.connection)
    @connection = connection
  end

  def fetch_tables
    @connection.execute(<<~SQL)
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
      ORDER BY table_name
    SQL
  end
end
```

### Generators

**Pattern**: Each PostgreSQL object type has dedicated generator

**Base Generator**:
```ruby
module BetterStructureSql
  module Generators
    class Base
      def initialize(config = BetterStructureSql.config)
        @config = config
      end

      def generate(object)
        raise NotImplementedError
      end
    end
  end
end
```

**Table Generator**:
```ruby
class TableGenerator < Base
  def generate(table)
    sql = ["CREATE TABLE #{table[:name]} ("]
    sql << generate_columns(table[:columns])
    sql << generate_constraints(table[:constraints])
    sql << ");"
    sql.join("\n")
  end

  private

  def generate_columns(columns)
    columns.map { |col| column_definition(col) }
  end

  def column_definition(column)
    parts = [column[:name], column[:type]]
    parts << "NOT NULL" unless column[:nullable]
    parts << "DEFAULT #{column[:default]}" if column[:default]
    parts.join(" ")
  end
end
```

### Dumper

**File**: `lib/better_structure_sql/dumper.rb`

**Responsibility**: Orchestrate dump process

**Flow**:
1. Initialize introspection
2. Fetch all database objects
3. Generate SQL for each object type (ordered)
4. Format output
5. Write to file
6. Optionally store version

```ruby
class Dumper
  def self.dump(output_path: nil, store_version: false)
    new(output_path: output_path).dump(store_version: store_version)
  end

  def dump(store_version: false)
    sql = build_sql
    write_file(sql)
    store_version(sql) if store_version && versioning_enabled?
  end

  private

  def build_sql
    [
      header,
      extensions_sql,
      types_sql,
      sequences_sql,
      tables_sql,
      indexes_sql,
      foreign_keys_sql,
      views_sql,
      functions_sql,
      triggers_sql,
      schema_migrations_sql,
      search_path_sql,
      footer
    ].compact.join("\n\n")
  end
end
```

### Formatter

**File**: `lib/better_structure_sql/formatter.rb`

**Responsibility**: Consistent SQL formatting

```ruby
class Formatter
  def initialize(config = BetterStructureSql.config)
    @config = config
    @indent = " " * config.indent_size
  end

  def format(sql)
    sql = normalize_whitespace(sql)
    sql = apply_indentation(sql)
    sql = capitalize_keywords(sql)
    sql
  end

  def indent(text, levels = 1)
    prefix = @indent * levels
    text.lines.map { |line| "#{prefix}#{line}" }.join
  end
end
```

### Schema Versions

**File**: `lib/better_structure_sql/schema_versions.rb`

**Responsibility**: Manage version storage

```ruby
module SchemaVersions
  def self.store_current
    content = File.read(config.output_path)
    pg_version = detect_pg_version
    format_type = detect_format_type

    SchemaVersion.create!(
      content: content,
      pg_version: pg_version,
      format_type: format_type
    )

    cleanup!
  end

  def self.cleanup!
    limit = config.schema_versions_limit
    return if limit.zero?

    versions_to_delete = SchemaVersion
      .order(created_at: :desc)
      .offset(limit)

    versions_to_delete.destroy_all
  end
end
```

### Dependency Resolver

**File**: `lib/better_structure_sql/dependency_resolver.rb`

**Responsibility**: Order objects by dependencies

```ruby
class DependencyResolver
  def resolve(objects)
    graph = build_dependency_graph(objects)
    topological_sort(graph)
  end

  private

  def build_dependency_graph(objects)
    # Build directed graph of dependencies
  end

  def topological_sort(graph)
    # Kahn's algorithm for topological sorting
  end
end
```

## Database Interaction

### Connection Management

Use ActiveRecord connection pool:
```ruby
def connection
  @connection ||= ActiveRecord::Base.connection
end
```

### Query Optimization

Batch queries where possible:
```ruby
def fetch_all_metadata
  {
    tables: fetch_tables,
    indexes: fetch_all_indexes,  # Single query for all indexes
    foreign_keys: fetch_all_foreign_keys  # Single query for all FKs
  }
end
```

Use prepared statements for repeated queries:
```ruby
def fetch_columns(table_name)
  @columns_stmt ||= connection.prepare(<<~SQL)
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_name = $1
    ORDER BY ordinal_position
  SQL

  connection.exec_prepared(@columns_stmt, [table_name])
end
```

## Error Handling

### Graceful Degradation

Handle missing features gracefully:
```ruby
def fetch_materialized_views
  return [] unless supports_materialized_views?

  connection.execute(materialized_views_query)
rescue ActiveRecord::StatementInvalid => e
  Rails.logger.warn("Materialized views not supported: #{e.message}")
  []
end
```

### Informative Errors

Provide actionable error messages:
```ruby
class SchemaVersionTableMissing < StandardError
  def initialize
    super(<<~MSG)
      Schema versions table not found.

      Run: rails generate better_structure_sql:install
           rails db:migrate
    MSG
  end
end
```

## Performance Optimizations

### Caching

Cache expensive queries within dump session:
```ruby
class Introspection
  def initialize(connection)
    @connection = connection
    @cache = {}
  end

  def fetch_tables
    @cache[:tables] ||= query_tables
  end
end
```

### Parallel Processing

Use threads for independent queries:
```ruby
def fetch_all_objects
  threads = [
    Thread.new { @extensions = fetch_extensions },
    Thread.new { @types = fetch_types },
    Thread.new { @tables = fetch_tables }
  ]

  threads.each(&:join)
end
```

### Memory Management

Stream large results:
```ruby
def write_large_table_data(table)
  File.open(output_path, 'a') do |f|
    connection.select_rows(query).each_slice(1000) do |batch|
      f.write(format_rows(batch))
    end
  end
end
```

## Testing Architecture

### Test Pyramid

```
         ┌─────────────┐
         │   E2E (5%)  │
         └─────────────┘
      ┌──────────────────┐
      │ Integration (20%)│
      └──────────────────┘
   ┌───────────────────────┐
   │    Unit Tests (75%)   │
   └───────────────────────┘
```

### Test Doubles

Use factories for test data:
```ruby
FactoryBot.define do
  factory :schema_version do
    content { "CREATE TABLE users ..." }
    pg_version { "14.5" }
    format_type { "sql" }
  end
end
```

Mock database queries in unit tests:
```ruby
RSpec.describe TableGenerator do
  let(:connection) { instance_double(ActiveRecord::Connection) }

  before do
    allow(connection).to receive(:execute).and_return(mock_result)
  end
end
```

### Integration Testing

Use real database with transactions:
```ruby
RSpec.configure do |config|
  config.use_transactional_fixtures = true

  config.before(:each) do
    create_test_schema
  end
end
```

## Rails Integration

### Railtie

```ruby
class Railtie < Rails::Railtie
  railtie_name :better_structure_sql

  rake_tasks do
    load "tasks/better_structure_sql.rake"
  end

  initializer "better_structure_sql.override_schema_dump" do
    if BetterStructureSql.config.replace_default_dump
      override_schema_dump_task
    end
  end
end
```

### Generator

```ruby
class InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def create_initializer
    template "initializer.rb", "config/initializers/better_structure_sql.rb"
  end

  def create_migration
    return unless versioning_enabled?

    migration_template "migration.rb",
      "db/migrate/create_better_structure_sql_schema_versions.rb"
  end
end
```

## Security Considerations

### SQL Injection Prevention

Use parameterized queries:
```ruby
# Bad
connection.execute("SELECT * FROM #{table_name}")

# Good
connection.execute(
  "SELECT * FROM information_schema.tables WHERE table_name = $1",
  [table_name]
)
```

### File Permissions

Set secure permissions on output:
```ruby
def write_file(content)
  File.write(output_path, content)
  File.chmod(0640, output_path)
end
```

### Sensitive Data

Never dump data, only structure:
```ruby
# Structure only, no data
def build_sql
  # Only DDL statements, no INSERT/COPY
end
```

## Extensibility

### Custom Generators

Allow plugins to add generators:
```ruby
BetterStructureSql.register_generator(:custom_object, CustomObjectGenerator)
```

### Hooks

Provide lifecycle hooks:
```ruby
BetterStructureSql.configure do |config|
  config.before_dump do |dumper|
    # Custom logic
  end

  config.after_dump do |dumper, output|
    # Post-processing
  end
end
```

## Future Considerations

### Multi-database Support
- MySQL adapter
- SQLite adapter

### Cloud Integration
- S3 storage for versions
- Database URL support

### CLI Tool
- Standalone binary
- Non-Rails usage
