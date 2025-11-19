# Schema Versions

Store and retrieve database schema versions with metadata tracking.

## Overview

Schema Versions feature stores snapshots of your database schema with:
- Full schema content (SQL or Ruby format)
- PostgreSQL version
- Format type (sql/rb)
- Creation timestamp
- Automatic cleanup based on retention limit

## Setup

### Enable in Configuration

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.enable_schema_versions = true
  config.schema_versions_limit = 10  # Keep last 10, 0 = unlimited
end
```

### Install Migration

```bash
rails generate better_structure_sql:install
rails db:migrate
```

Creates table: `better_structure_sql_schema_versions`

## Database Schema

```sql
CREATE TABLE better_structure_sql_schema_versions (
  id bigserial PRIMARY KEY,
  content text NOT NULL,
  pg_version varchar NOT NULL,
  format_type varchar NOT NULL,
  created_at timestamp(6) NOT NULL
);

CREATE INDEX index_schema_versions_on_created_at
  ON better_structure_sql_schema_versions (created_at DESC);
```

## Usage

### Store Schema Version

```bash
# Store after migration
rails db:migrate
rails db:schema:store
```

### List Versions

```bash
rails db:schema:versions
```

Output:
```
Schema Versions (5 total):
  #5 - 2024-01-20 14:30:22 UTC - PostgreSQL 14.5 (sql) - 15.2 KB
  #4 - 2024-01-19 10:15:45 UTC - PostgreSQL 14.5 (sql) - 14.8 KB
  #3 - 2024-01-18 09:22:33 UTC - PostgreSQL 14.5 (sql) - 14.5 KB
```

### Programmatic Access

```ruby
# Get latest version
latest = BetterStructureSql::SchemaVersions.latest
puts latest.content
puts latest.pg_version  # "14.5"
puts latest.format_type # "sql"
puts latest.created_at  # 2024-01-20 14:30:22 UTC

# Get all versions
versions = BetterStructureSql::SchemaVersions.all_versions

# Find specific version
version = BetterStructureSql::SchemaVersions.find(3)

# Count versions
count = BetterStructureSql::SchemaVersions.count
```

## Automatic Cleanup

When `schema_versions_limit` is set, old versions are automatically deleted.

```ruby
# Keep last 10 versions
config.schema_versions_limit = 10

# Keep all versions
config.schema_versions_limit = 0

# Manual cleanup
BetterStructureSql::SchemaVersions.cleanup!
```

Cleanup happens automatically after `db:schema:store`.

## Model Reference

```ruby
class BetterStructureSql::SchemaVersion < ActiveRecord::Base
  # Attributes
  # - id: integer
  # - content: text (schema SQL/Ruby content)
  # - pg_version: string (PostgreSQL version)
  # - format_type: string ('sql' or 'rb')
  # - created_at: datetime

  # Class Methods
  def self.store_current
    # Store current schema as new version
  end

  def self.latest
    # Get most recent version
  end

  def self.all_versions
    # Get all versions ordered by created_at DESC
  end

  def self.cleanup!
    # Remove old versions per retention limit
  end

  # Instance Methods
  def size
    # Content size in bytes
  end

  def formatted_size
    # Human-readable size (e.g., "15.2 KB")
  end
end
```

## API Endpoint Example

Expose schema versions to developers via authenticated endpoint.

### Controller Example

```ruby
# app/controllers/api/v1/schema_versions_controller.rb
module Api
  module V1
    class SchemaVersionsController < ApplicationController
      before_action :authenticate_developer!

      # GET /api/v1/schema_versions
      def index
        versions = BetterStructureSql::SchemaVersions.all_versions
        render json: {
          versions: versions.map do |v|
            {
              id: v.id,
              pg_version: v.pg_version,
              format_type: v.format_type,
              created_at: v.created_at,
              size: v.formatted_size
            }
          end
        }
      end

      # GET /api/v1/schema_versions/latest
      def latest
        version = BetterStructureSql::SchemaVersions.latest
        render json: {
          id: version.id,
          content: version.content,
          pg_version: version.pg_version,
          format_type: version.format_type,
          created_at: version.created_at
        }
      end

      # GET /api/v1/schema_versions/:id
      def show
        version = BetterStructureSql::SchemaVersions.find(params[:id])
        render json: {
          id: version.id,
          content: version.content,
          pg_version: version.pg_version,
          format_type: version.format_type,
          created_at: version.created_at
        }
      end

      private

      def authenticate_developer!
        # Implement authentication
        # Example: token, OAuth, session, etc.
        authenticate_or_request_with_http_token do |token, options|
          ActiveSupport::SecurityUtils.secure_compare(
            token,
            ENV['SCHEMA_API_TOKEN']
          )
        end
      end
    end
  end
end
```

### Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :schema_versions, only: [:index, :show] do
      collection do
        get :latest
      end
    end
  end
end
```

### Client Usage

```bash
# Get latest schema
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.yourapp.com/api/v1/schema_versions/latest

# List all versions
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.yourapp.com/api/v1/schema_versions

# Get specific version
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api.yourapp.com/api/v1/schema_versions/5
```

### Download Schema Script

```bash
#!/bin/bash
# scripts/download_schema.sh

TOKEN="your_api_token"
API_URL="https://api.yourapp.com/api/v1/schema_versions/latest"

curl -H "Authorization: Bearer $TOKEN" "$API_URL" | \
  jq -r '.content' > db/structure.sql

echo "Schema downloaded to db/structure.sql"
```

## Use Cases

### Developer Onboarding

New developers download latest schema instead of running migrations:

```bash
# Download latest schema
./scripts/download_schema.sh

# Load schema
rails db:schema:load

# Start working
rails db:seed
```

### Schema Comparison

```ruby
# Compare two versions
v1 = BetterStructureSql::SchemaVersions.find(10)
v2 = BetterStructureSql::SchemaVersions.find(15)

File.write('/tmp/v1.sql', v1.content)
File.write('/tmp/v2.sql', v2.content)

system('diff -u /tmp/v1.sql /tmp/v2.sql')
```

### Rollback Schema

```ruby
# Restore previous version
old_version = BetterStructureSql::SchemaVersions.find(5)

File.write('db/structure.sql', old_version.content)
system('rails db:schema:load')
```

### CI/CD Schema Validation

```ruby
# spec/schema_spec.rb
RSpec.describe 'Database Schema' do
  it 'matches latest stored version' do
    BetterStructureSql::Dumper.dump_to_string

    latest = BetterStructureSql::SchemaVersions.latest
    current = File.read('db/structure.sql')

    expect(current).to eq(latest.content)
  end
end
```

## Works with schema.rb

Schema versions work with both `structure.sql` and `schema.rb`:

```ruby
# Store schema.rb version
content = File.read('db/schema.rb')
BetterStructureSql::SchemaVersions.store(
  content: content,
  format_type: 'rb',
  pg_version: ActiveRecord::Base.connection.select_value('SHOW server_version')
)
```

## Performance Considerations

### Large Schemas

For very large schemas (>1MB):
- Consider compression
- Use pagination in API
- Implement caching

### Storage

Typical schema sizes:
- Small app (10 tables): ~5-10 KB per version
- Medium app (100 tables): ~50-100 KB per version
- Large app (500 tables): ~200-500 KB per version

With 10 version limit:
- Small: ~100 KB total
- Medium: ~1 MB total
- Large: ~5 MB total

### Cleanup Strategy

```ruby
# Aggressive cleanup (keep last 5)
config.schema_versions_limit = 5

# Conservative (keep last 50)
config.schema_versions_limit = 50

# Archive old versions before cleanup
BetterStructureSql::SchemaVersions.where('created_at < ?', 1.year.ago).each do |v|
  File.write("archive/schema_#{v.id}.sql", v.content)
end
```

## Next Steps

- [Configuration](configuration.md)
- [Usage Examples](usage.md)
