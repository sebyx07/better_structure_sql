# BetterStructureSql SQLite Integration App

This is a minimal Rails application for testing BetterStructureSql with **SQLite** database.

## Purpose

- Test SQLite adapter implementation
- Validate sqlite_master and PRAGMA introspection queries
- Test SQLite-specific SQL generation
- Demonstrate feature limitations compared to PostgreSQL/MySQL
- Test file-based database support

## Key Differences from PostgreSQL/MySQL Integration

### Features NOT Supported in SQLite
- ❌ Extensions
- ❌ Custom ENUM types (using TEXT + CHECK constraint instead)
- ❌ Composite types (using JSON TEXT instead)
- ❌ Domain types (using CHECK constraints instead)
- ❌ Materialized views
- ❌ Sequences (using AUTOINCREMENT instead)
- ❌ Array columns (using JSON TEXT instead)
- ❌ Stored procedures/functions
- ❌ ALTER TABLE ADD CONSTRAINT for foreign keys (must be inline)

### SQLite-Specific Features
- ✅ Triggers (simplified, no plpgsql)
- ✅ Regular views
- ✅ CHECK constraints
- ✅ INTEGER PRIMARY KEY AUTOINCREMENT
- ✅ File-based database (no server process)
- ✅ PRAGMA-based introspection
- ✅ sqlite_master system table

## Setup

### Local Setup (No Docker Required)

```bash
cd integration_sqlite
bundle install
bundle exec rails db:create db:migrate
bundle exec rails db:schema:dump
```

### Testing

```bash
# Dump schema
bundle exec rails db:schema:dump

# Store version
bundle exec rails db:schema:save

# List versions
bundle exec rails db:schema:versions
```

## SQLite Type Affinities

SQLite uses type affinities instead of strict types:

- **TEXT**: For text/varchar/char types, timestamps (ISO8601), JSON
- **NUMERIC**: For numeric types without specified precision
- **INTEGER**: For integer types, booleans (0/1), auto-increment
- **REAL**: For floating point types
- **BLOB**: For binary data

## Foreign Keys

SQLite requires foreign keys to be defined inline with CREATE TABLE. The migrations demonstrate the table recreation pattern required for adding foreign keys to existing tables.

Enable foreign key enforcement:
```sql
PRAGMA foreign_keys = ON;
```

## Limitations

### ALTER TABLE Restrictions
- Cannot add foreign keys via ALTER TABLE
- Limited column modification support
- May require table recreation for schema changes

### Trigger Limitations
- No plpgsql support
- Basic SQL expressions only
- Limited function calls

### Type System
- Type affinities (not strict types)
- May lose precision for DECIMAL → REAL
- Timestamps stored as TEXT (ISO8601)
