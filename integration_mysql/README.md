# BetterStructureSql MySQL Integration App

This is a minimal Rails application for testing BetterStructureSql with **MySQL** database.

## Purpose

- Test MySQL adapter implementation
- Validate information_schema introspection queries
- Test MySQL-specific SQL generation
- Ensure feature parity where possible
- Test multi-database support alongside PostgreSQL

## Key Differences from PostgreSQL Integration

### Features NOT Supported in MySQL
- ❌ Extensions
- ❌ Custom ENUM types (using inline ENUMs instead)
- ❌ Composite types (using JSON instead)
- ❌ Domain types (using CHECK constraints for MySQL 8.0.16+)
- ❌ Materialized views
- ❌ Sequences (using AUTO_INCREMENT instead)
- ❌ Array columns (using JSON arrays instead)

### MySQL-Specific Features
- ✅ Stored procedures
- ✅ Triggers
- ✅ Regular views
- ✅ JSON data type (MySQL 5.7+)
- ✅ CHECK constraints (MySQL 8.0.16+)

## Setup

### Docker Compose

```bash
docker-compose -f docker-compose.mysql.yml up
```

### Manual Setup

```bash
cd integration_mysql
bundle install
bundle exec rails db:create db:migrate
bundle exec rails db:schema:dump
```

## Testing

```bash
# Dump schema
bundle exec rails db:schema:dump

# Store version
bundle exec rails db:schema:save

# List versions
bundle exec rails db:schema:versions
```
