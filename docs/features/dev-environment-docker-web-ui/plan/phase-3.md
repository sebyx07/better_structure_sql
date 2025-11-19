# Phase 3: Integration App Configuration Support

## Objective

Enable integration app to load custom configurations for database connections and BetterStructureSql settings, supporting future multi-database type compatibility while working with PostgreSQL currently.

## Deliverables

### Custom Database Configuration

**`integration/config/database.yml`**
- Template with environment variable substitution
- Development environment (PostgreSQL via Docker)
- Test environment (isolated test database)
- Production-like staging environment
- Comments documenting future multi-DB support
- Adapter-agnostic settings where possible

**Environment Variable Support**
- DATABASE_URL for full connection string
- DB_ADAPTER (postgresql, mysql2, sqlite3 - future)
- DB_HOST, DB_PORT, DB_NAME, DB_USERNAME, DB_PASSWORD
- Defaults for Docker environment
- Override capability for different setups

**Database Initializer**
- Check for custom database.yml in config/
- Load and validate configuration
- Log active database adapter
- Warn if unsupported features detected
- Graceful degradation for missing extensions

### Custom Gem Configuration

**`integration/config/initializers/better_structure_sql.rb`**
- Output path configuration (db/structure.sql or db/schema.rb)
- Schema format selection (sql/ruby)
- Versioning enable/disable toggle
- Retention limit setting
- Feature flags (extensions, views, functions, triggers)
- Environment-specific configurations
- Comments with all available options

**Configuration Loader**
- Load initializer on app startup
- Validate configuration values
- Apply defaults for missing settings
- Log configuration summary
- Support ENV overrides

**Multi-Format Support**
- Toggle between structure.sql and schema.rb formats
- Update schema_versions.format_type accordingly
- Store both formats if needed
- Document format implications

### Configuration Documentation

**README Section: Configuration**
- All available settings explained
- Environment variable reference
- Example configurations for common scenarios
- Multi-database compatibility notes
- Migration guide for different formats

**Example Configurations**
- PostgreSQL with structure.sql (default)
- PostgreSQL with schema.rb
- Future: MySQL with structure.sql
- Future: SQLite with schema.rb
- Testing configuration

### Seed Data Enhancement

**`integration/db/seeds.rb`**
- Generate sample schema versions
- Include both SQL and Ruby format examples
- Different PostgreSQL versions
- Realistic schema content
- Created_at timestamps spread over time
- Test retention limit behavior

**Sample Schema Content**
- Simple schema (few tables)
- Complex schema (many tables, views, functions)
- Schema with extensions
- Schema with custom types
- Schema with triggers and functions

## Testing Requirements

### Configuration Loading Tests
- [ ] Default configuration loads successfully
- [ ] Custom database.yml overrides defaults
- [ ] Environment variables override file config
- [ ] Invalid configuration raises helpful error
- [ ] Missing optional settings use defaults

### Database Connection Tests
- [ ] PostgreSQL connection works with custom config
- [ ] Connection pooling respects settings
- [ ] Test environment uses separate database
- [ ] Connection recovery after database restart
- [ ] Multiple database support (primary/replica)

### Format Selection Tests
- [ ] structure.sql format generates SQL dump
- [ ] schema.rb format generates Ruby dump
- [ ] Format type stored correctly in schema_versions
- [ ] Format affects dump command behavior
- [ ] Format visible in web UI

### Versioning Configuration Tests
- [ ] Versioning can be disabled
- [ ] Retention limit enforced correctly
- [ ] Zero limit means unlimited retention
- [ ] Cleanup respects configured limit
- [ ] Configuration change doesn't break existing versions

### Seed Data Tests
- [ ] Seeds create expected number of versions
- [ ] Versions have different formats
- [ ] Versions span time range for UI testing
- [ ] Content is valid SQL/Ruby
- [ ] Rerunning seeds is idempotent

## Success Criteria

1. Custom database.yml loaded and respected
2. BetterStructureSql configuration customizable via initializer
3. Environment variables override file settings
4. Both structure.sql and schema.rb formats supported
5. Seed data creates realistic test scenarios
6. Configuration documented with examples
7. Future multi-database support architecture established
8. All tests pass with custom configurations
9. Web UI displays format type correctly
10. Configuration changes don't require code modifications

## Dependencies

### External Dependencies
- None (uses existing Rails configuration system)

### Internal Dependencies
- Phase 1 completed (Docker environment)
- Phase 2 completed (Web UI engine)
- Existing configuration system in gem

## Implementation Steps

1. Create database.yml template with ENV support
2. Add environment variable documentation
3. Create BetterStructureSql initializer template
4. Document all configuration options
5. Add configuration validation
6. Create seed data with sample versions
7. Add format selection logic
8. Test with different configurations
9. Update documentation with examples
10. Add configuration tests
11. Verify multi-environment support

## Validation

### Manual Testing - Database Configuration
```bash
# Test default configuration
docker compose up
docker compose exec web rails dbconsole
\conninfo

# Test environment variable override
docker compose down
export DB_NAME=custom_db
docker compose up
# Verify connection to custom_db

# Test different adapters (future)
# Change DB_ADAPTER=mysql2
# Verify appropriate behavior
```

### Manual Testing - Gem Configuration
```bash
# Edit integration/config/initializers/better_structure_sql.rb
# Change output format to schema.rb
docker compose restart web

# Generate dump
docker compose exec web rails db:schema:dump_better

# Verify format
docker compose exec web ls -la db/
# Should see schema.rb

# Check web UI
open http://localhost:3000/better_structure_sql/schema_versions
# Should show "ruby" format type
```

### Manual Testing - Seed Data
```bash
# Load seeds
docker compose exec web rails db:seed

# Verify in console
docker compose exec web rails console
BetterStructureSql::SchemaVersion.count
# Should match seed count

BetterStructureSql::SchemaVersion.pluck(:format_type).uniq
# Should include both 'sql' and 'ruby'

# Verify in web UI
open http://localhost:3000/better_structure_sql/schema_versions
# Should see multiple versions with different formats
```

### Automated Testing
```bash
# Test configuration loading
docker compose exec web bundle exec rspec spec/configuration

# Test with different env vars
DB_NAME=test_custom docker compose exec web bundle exec rspec

# Test seed data
docker compose exec web rails db:seed
docker compose exec web bundle exec rspec spec/models/schema_version
```

## Configuration Examples for Documentation

### PostgreSQL with structure.sql (Default)
```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.output_path = "db/structure.sql"
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
  config.include_extensions = true
  config.include_views = true
end
```

### PostgreSQL with schema.rb
```ruby
BetterStructureSql.configure do |config|
  config.output_path = "db/schema.rb"
  config.enable_schema_versions = true
  config.schema_versions_limit = 5
  # Extensions not applicable for schema.rb
  config.include_views = false
end
```

### Environment-Specific Configuration
```ruby
BetterStructureSql.configure do |config|
  if Rails.env.production?
    config.enable_schema_versions = false  # Don't store in production
    config.output_path = "db/structure.sql"
  else
    config.enable_schema_versions = true
    config.schema_versions_limit = 10
    config.output_path = ENV.fetch('SCHEMA_FORMAT', 'db/structure.sql')
  end
end
```

### Future MySQL Support Example
```ruby
# config/database.yml (future)
development:
  adapter: mysql2  # or trilogy
  encoding: utf8mb4
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: mysql
  database: better_structure_sql_dev
  username: root
  password: password

# BetterStructureSql would detect adapter and:
# - Skip PostgreSQL-specific features (extensions, pg_catalog)
# - Use MySQL information_schema queries
# - Generate MySQL-compatible SQL
```

## Rollback Plan

If phase fails:
- Revert to hardcoded configuration
- Keep Phases 1 and 2 functionality
- Document configuration as "future enhancement"
- Custom configs can be manual file edits
