# Testing Guide

Comprehensive testing strategy for BetterStructureSql gem using RSpec.

## Test Structure

```
spec/
├── spec_helper.rb
├── rails_helper.rb
├── support/
│   ├── database_helpers.rb
│   ├── schema_helpers.rb
│   └── comparison_helpers.rb
├── better_structure_sql/
│   ├── configuration_spec.rb
│   ├── dumper_spec.rb
│   ├── formatter_spec.rb
│   ├── introspection_spec.rb
│   ├── schema_migrations_spec.rb
│   ├── schema_version_spec.rb
│   ├── schema_versions_spec.rb
│   ├── pg_version_spec.rb
│   ├── dependency_resolver_spec.rb
│   └── generators/
│       ├── extension_generator_spec.rb
│       ├── type_generator_spec.rb
│       ├── table_generator_spec.rb
│       ├── index_generator_spec.rb
│       ├── foreign_key_generator_spec.rb
│       ├── view_generator_spec.rb
│       ├── function_generator_spec.rb
│       └── trigger_generator_spec.rb
├── integration/
│   ├── dumper_integration_spec.rb
│   ├── schema_versioning_spec.rb
│   ├── schema_comparison_spec.rb
│   └── rails_integration_spec.rb
├── performance/
│   └── benchmark_spec.rb
└── dummy/
    └── (Rails app for testing)
```

## Unit Tests

### Configuration Tests

```ruby
# spec/better_structure_sql/configuration_spec.rb
RSpec.describe BetterStructureSql::Configuration do
  describe 'defaults' do
    it 'sets default output_path' do
      expect(config.output_path).to eq('db/structure.sql')
    end

    it 'sets default schema_versions_limit' do
      expect(config.schema_versions_limit).to eq(10)
    end
  end

  describe 'validation' do
    it 'validates schema_versions_limit >= 0' do
      expect { config.schema_versions_limit = -1 }.to raise_error(ArgumentError)
    end
  end
end
```

### Introspection Tests

```ruby
# spec/better_structure_sql/introspection_spec.rb
RSpec.describe BetterStructureSql::Introspection do
  let(:introspection) { described_class.new }

  describe '#fetch_extensions' do
    it 'returns all installed extensions' do
      extensions = introspection.fetch_extensions
      expect(extensions).to include('plpgsql', 'pgcrypto')
    end
  end

  describe '#fetch_tables' do
    it 'returns all tables with columns' do
      tables = introspection.fetch_tables
      expect(tables).to be_an(Array)
      expect(tables.first).to have_key(:name)
      expect(tables.first).to have_key(:columns)
    end
  end

  describe '#fetch_indexes' do
    it 'includes unique indexes' do
      indexes = introspection.fetch_indexes
      unique_indexes = indexes.select { |i| i[:unique] }
      expect(unique_indexes).not_to be_empty
    end

    it 'includes partial indexes with condition' do
      create_partial_index
      indexes = introspection.fetch_indexes
      partial = indexes.find { |i| i[:condition].present? }
      expect(partial).to be_present
    end
  end
end
```

### Generator Tests

```ruby
# spec/better_structure_sql/generators/table_generator_spec.rb
RSpec.describe BetterStructureSql::Generators::TableGenerator do
  let(:generator) { described_class.new }

  describe '#generate' do
    it 'generates CREATE TABLE statement' do
      table = {
        name: 'users',
        columns: [
          { name: 'id', type: 'bigserial', nullable: false },
          { name: 'email', type: 'varchar', nullable: false }
        ]
      }

      sql = generator.generate(table)
      expect(sql).to include('CREATE TABLE users')
      expect(sql).to include('id bigserial NOT NULL')
      expect(sql).to include('email varchar NOT NULL')
    end

    it 'includes primary key constraint' do
      table = build_table_with_primary_key
      sql = generator.generate(table)
      expect(sql).to include('PRIMARY KEY (id)')
    end
  end
end
```

### Schema Version Tests

```ruby
# spec/better_structure_sql/schema_versions_spec.rb
RSpec.describe BetterStructureSql::SchemaVersions do
  describe '.store_current' do
    it 'creates new version record' do
      expect {
        described_class.store_current
      }.to change(BetterStructureSql::SchemaVersion, :count).by(1)
    end

    it 'stores PostgreSQL version' do
      version = described_class.store_current
      expect(version.pg_version).to match(/\d+\.\d+/)
    end
  end

  describe '.cleanup!' do
    context 'with limit 5' do
      before { BetterStructureSql.config.schema_versions_limit = 5 }

      it 'keeps only 5 most recent versions' do
        10.times { described_class.store_current }
        described_class.cleanup!
        expect(described_class.count).to eq(5)
      end
    end

    context 'with limit 0' do
      before { BetterStructureSql.config.schema_versions_limit = 0 }

      it 'keeps all versions' do
        10.times { described_class.store_current }
        described_class.cleanup!
        expect(described_class.count).to eq(10)
      end
    end
  end
end
```

## Integration Tests

### Schema Comparison Tests

```ruby
# spec/integration/schema_comparison_spec.rb
RSpec.describe 'Schema Comparison' do
  let(:pg_dump_output) { generate_pg_dump }
  let(:better_sql_output) { BetterStructureSql::Dumper.dump_to_string }

  it 'includes all tables from pg_dump' do
    pg_tables = extract_tables(pg_dump_output)
    better_tables = extract_tables(better_sql_output)
    expect(better_tables).to match_array(pg_tables)
  end

  it 'includes all indexes from pg_dump' do
    pg_indexes = extract_indexes(pg_dump_output)
    better_indexes = extract_indexes(better_sql_output)
    expect(better_indexes).to match_array(pg_indexes)
  end

  it 'produces cleaner output than pg_dump' do
    expect(better_sql_output.lines.count).to be < pg_dump_output.lines.count
    expect(better_sql_output).not_to include('Dumped from database version')
    expect(better_sql_output).not_to include('Dumped by pg_dump')
  end

  it 'is deterministic' do
    output1 = BetterStructureSql::Dumper.dump_to_string
    output2 = BetterStructureSql::Dumper.dump_to_string
    expect(output1).to eq(output2)
  end
end
```

### Full Integration Tests

```ruby
# spec/integration/dumper_integration_spec.rb
RSpec.describe 'Dumper Integration' do
  it 'generates valid SQL that can be loaded' do
    # Generate schema
    BetterStructureSql::Dumper.dump(output_path: '/tmp/test_structure.sql')

    # Drop and recreate database
    recreate_database

    # Load generated schema
    load_schema('/tmp/test_structure.sql')

    # Verify all objects exist
    expect(table_exists?('users')).to be true
    expect(extension_exists?('pgcrypto')).to be true
    expect(index_exists?('index_users_on_email')).to be true
  end

  it 'handles complex schema with all features' do
    create_complex_schema # from dummy app

    sql = BetterStructureSql::Dumper.dump_to_string

    expect(sql).to include('CREATE EXTENSION')
    expect(sql).to include('CREATE TYPE')
    expect(sql).to include('CREATE TABLE')
    expect(sql).to include('CREATE INDEX')
    expect(sql).to include('CREATE VIEW')
    expect(sql).to include('CREATE FUNCTION')
    expect(sql).to include('CREATE TRIGGER')
    expect(sql).to include('ALTER TABLE')
    expect(sql).to include('INSERT INTO "schema_migrations"')
  end
end
```

### Rails Integration Tests

```ruby
# spec/integration/rails_integration_spec.rb
RSpec.describe 'Rails Integration' do
  it 'replaces rake db:schema:dump when configured' do
    BetterStructureSql.config.replace_default_dump = true

    # Run rake task
    Rake::Task['db:schema:dump'].invoke

    # Verify BetterStructureSql was used
    content = File.read('db/structure.sql')
    expect(content).not_to include('pg_dump')
  end

  it 'provides db:schema:dump_better task' do
    Rake::Task['db:schema:dump_better'].invoke
    expect(File.exist?('db/structure.sql')).to be true
  end
end
```

## Performance Tests

```ruby
# spec/performance/benchmark_spec.rb
RSpec.describe 'Performance Benchmarks' do
  it 'dumps 100 tables in under 5 seconds' do
    create_tables(100)

    time = Benchmark.realtime do
      BetterStructureSql::Dumper.dump
    end

    expect(time).to be < 5.0
  end

  it 'dumps 500 tables in under 20 seconds' do
    create_tables(500)

    time = Benchmark.realtime do
      BetterStructureSql::Dumper.dump
    end

    expect(time).to be < 20.0
  end

  it 'memory usage stays reasonable' do
    create_complex_schema(table_count: 500)

    memory_before = memory_usage
    BetterStructureSql::Dumper.dump
    memory_after = memory_usage

    memory_increase = memory_after - memory_before
    expect(memory_increase).to be < 100 # MB
  end
end
```

## Test Helpers

```ruby
# spec/support/schema_helpers.rb
module SchemaHelpers
  def create_complex_schema
    enable_extensions
    create_custom_types
    create_tables
    create_indexes
    create_foreign_keys
    create_views
    create_functions
    create_triggers
  end

  def enable_extensions
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto"
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\""
  end

  def create_custom_types
    execute "CREATE TYPE user_role AS ENUM ('admin', 'user', 'guest')"
    execute "CREATE DOMAIN email AS varchar(255) CHECK (VALUE ~ '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$')"
  end

  def extract_tables(sql)
    sql.scan(/CREATE TABLE (\w+)/).flatten
  end

  def extract_indexes(sql)
    sql.scan(/CREATE (?:UNIQUE )?INDEX (\w+)/).flatten
  end
end
```

```ruby
# spec/support/comparison_helpers.rb
module ComparisonHelpers
  def generate_pg_dump
    `pg_dump --schema-only #{database_name}`
  end

  def normalize_sql(sql)
    sql.gsub(/--.*$/, '')         # Remove comments
       .gsub(/\s+/, ' ')           # Normalize whitespace
       .strip
  end

  def compare_schemas(schema1, schema2)
    normalized1 = normalize_sql(schema1)
    normalized2 = normalize_sql(schema2)

    {
      tables_diff: table_diff(normalized1, normalized2),
      indexes_diff: index_diff(normalized1, normalized2),
      views_diff: view_diff(normalized1, normalized2)
    }
  end
end
```

## Running Tests

### All tests
```bash
bundle exec rspec
```

### Unit tests only
```bash
bundle exec rspec spec/better_structure_sql
```

### Integration tests only
```bash
bundle exec rspec spec/integration
```

### Specific test file
```bash
bundle exec rspec spec/better_structure_sql/dumper_spec.rb
```

### With coverage
```bash
COVERAGE=true bundle exec rspec
```

### Performance tests
```bash
bundle exec rspec spec/performance --tag performance
```

## CI Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Setup database
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/better_structure_sql_test
        run: |
          bundle exec rails db:create
          bundle exec rails db:migrate

      - name: Run tests
        run: bundle exec rspec

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Test Coverage Goals

- Unit tests: 100% code coverage
- Integration tests: All major features
- Performance tests: Key benchmarks
- Edge cases: All error conditions
- Overall: >95% coverage

## Best Practices

1. **Isolation**: Each test creates/destroys its own data
2. **Speed**: Use database transactions for rollback
3. **Clarity**: Descriptive test names and contexts
4. **Coverage**: Test both success and failure paths
5. **Realism**: Use dummy app with real complexity
