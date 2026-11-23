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

Point the app at any MySQL 8.0+ or MariaDB 10.6+ server:

```bash
cd integration_mysql
bundle install
export DB_HOST=127.0.0.1 DB_PORT=3306 DB_USERNAME=root DB_PASSWORD=root
export REPLACE_DEFAULT_DUMP=true REPLACE_DEFAULT_LOAD=true  # dump and load through the gem
bin/rails db:create db:migrate
```

| Variable | Default | Meaning |
|---|---|---|
| `DB_ADAPTER` | `mysql2` | ActiveRecord driver: `mysql2` or `trilogy` (Rails' default) |
| `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD` | `localhost`, `3306`, `root`, empty | Server connection |
| `MULTI_FILE_SCHEMA` | `true` | `false` dumps to `db/structure.sql` instead of `db/schema/` |
| `REPLACE_DEFAULT_LOAD` | `false` | Keep `true`: Rails' own `db:schema:load` pipes the file through the `mysql` client, which cannot load routines or triggers with `BEGIN ... END` bodies without `DELIMITER` |

## Testing

```bash
# Round trip: dump development, load the dump into a freshly purged test
# database, dump again. Fails unless both dumps are byte-identical and every
# object's SHOW CREATE output matches in both databases.
bin/rails bss:round_trip
ROUND_TRIP_LAYOUT=multi_file bin/rails bss:round_trip   # same, with the directory layout

# Dump, store and list versions
bin/rails db:schema:dump_better
bin/rails db:schema:store
bin/rails db:schema:versions
```

`db/migrate/20250201000001_create_mysql_feature_showcase.rb` holds the DDL the
round trip must preserve (generated columns, functional/prefix/FULLTEXT
indexes, composite foreign keys, CHECK constraints, ordered triggers, nested
`BEGIN ... END` procedures, charsets and collations). Round-trip output lands in
`tmp/round_trip/`.
