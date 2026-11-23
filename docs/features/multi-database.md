# Database adapters

One adapter per database, selected from `ActiveRecord::Base.connection.adapter_name` by [`Adapters::Registry`](../../lib/better_structure_sql/adapters/registry.rb).

| Connection adapter | Adapter class | Status |
|---|---|---|
| `postgresql`, `postgis` | `PostgresqlAdapter` | Primary target |
| `mysql2`, `trilogy` | `MysqlAdapter` | Supported, round-trip tested in CI; requires the matching driver gem (`mysql2` or `trilogy`) |
| `sqlite3` | `SqliteAdapter` | Supported, round-trip tested in CI; requires the `sqlite3` gem |

PostgreSQL has the widest feature coverage and its round trip runs in the spec suite (`spec/integration/postgresql_round_trip_spec.rb`). MySQL, MariaDB and SQLite are covered by adapter specs plus a round trip in their integration app: dump, load into an empty database, dump again, and fail unless both dumps are byte-identical and the database reports the same DDL on both sides. The servers and drivers tested are the `integration-*` jobs in [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml).

## Capability flags

From each adapter's `supports_*?` methods:

| Flag | PostgreSQL | MySQL | SQLite |
|---|---|---|---|
| `supports_extensions?` | true | false | false |
| `supports_custom_types?` | true | false | false |
| `supports_domains?` | true | false | false |
| `supports_sequences?` | true | false | false |
| `supports_materialized_views?` | true | false | false |
| `supports_functions?` | true | true | false |
| `supports_triggers?` | true | true | true |
| `supports_comments?` | true | true | false |

An unsupported object type yields an empty list, so the matching `include_*` option needs no per-database setting. A failing introspection query raises; it is never swallowed into an empty section.

## PostgreSQL

Reads `pg_catalog` and uses the server's own deparse functions (`pg_get_indexdef`, `pg_get_constraintdef`, `pg_get_functiondef`, `pg_get_triggerdef`, `format_type`), so the SQL is what the server itself would print. Objects owned by an extension are skipped: `CREATE EXTENSION` recreates them.

| Object | Output |
|---|---|
| Extensions | `CREATE EXTENSION IF NOT EXISTS ...`, with `CREATE SCHEMA` first when the extension lives outside `public` |
| Enum, composite, range types | `CREATE TYPE ... AS ENUM (...)`, `AS (...)`, `AS RANGE (...)`, ordered with domains so each follows the types it uses |
| Domains | `CREATE DOMAIN` with default, `NOT NULL` and every check constraint; a domain (or type) that calls a function is written among the functions, after it |
| Functions, procedures | `pg_get_functiondef` output |
| Sequences | `CREATE SEQUENCE IF NOT EXISTS`; `ALTER SEQUENCE ... OWNED BY` for serial columns |
| Tables | `CREATE [UNLOGGED] TABLE IF NOT EXISTS` with columns, collations, defaults, identity (`GENERATED ... AS IDENTITY`) and generated columns, primary key, check, unique and exclusion constraints, storage parameters (`WITH (fillfactor=70)`) |
| Inheritance | `INHERITS (parent, ...)` with only the child's own columns and constraints; a child is written right after the last of its parents |
| Partitioned tables | `PARTITION BY` on the parent; each partition as `PARTITION OF ... FOR VALUES`, written after its parent |
| `NOT VALID` constraints | Added with `ALTER TABLE` after the table |
| Indexes | Full definition: access method, partial `WHERE`, expressions, `UNIQUE` |
| Foreign keys | `ALTER TABLE ... ADD CONSTRAINT` with the server's definition: composite keys, `MATCH FULL`, actions, `DEFERRABLE`, `NOT VALID` |
| Views | `CREATE OR REPLACE VIEW`, with view options, ordered so a view comes after the views it selects from |
| Materialized views | `CREATE MATERIALIZED VIEW IF NOT EXISTS` and its indexes |
| Triggers | `pg_get_triggerdef` output |
| Comments | `COMMENT ON` for tables, columns, indexes, views, functions, procedures |

Formatting: identifiers are always double-quoted; type names use the short forms (`varchar`, `timestamp(6)`, `timestamptz`).

Header: `SET client_encoding = 'UTF8';`, `SET standard_conforming_strings = on;`, `SET check_function_bodies = false;`, then `SET search_path TO <config.search_path>;`.

Not supported:

- Aggregates, rules, row-level security policies, event triggers.
- Schemas other than `public`: every object is read from `public` only (an extension may live in any schema).
- Comments on types, sequences, constraints and triggers.

Known limitation: a `CHECK` written as `col IN ('a', 'b')` on a `varchar` column can change text once. PostgreSQL stores it as `= ANY ((ARRAY['a'::character varying, 'b'::character varying])::text[])`, and when that text is loaded it normalizes it again to `= ANY (ARRAY[('a'::character varying)::text, ('b'::character varying)::text])`. So the first dump of a database created from a dump differs from the dump that created it in those constraints; from then on the text is stable. The two forms mean the same, and `pg_dump` behaves the same way, because both print the server's `pg_get_constraintdef` output.

## MySQL

Works with the `mysql2` and `trilogy` drivers (the registry requires the gem matching the connection) and with MariaDB servers.

| Object | Output |
|---|---|
| Tables | `CREATE TABLE IF NOT EXISTS`, backtick-quoted, ending in the table options `ENGINE=... DEFAULT COLLATE=...` |
| Columns | The server's own column type, verbatim: `int unsigned`, `datetime(6)`, `tinyint(1)`, `enum(...)`, `set(...)`. A column `COLLATE` only where it differs from the table's. `AUTO_INCREMENT`, `ON UPDATE ...`, generated columns (`GENERATED ALWAYS AS (...) VIRTUAL \| STORED`) |
| Defaults | As SQL: quoted literals, bare numbers and bit values, expression defaults in parentheses, `CURRENT_TIMESTAMP(n)` as is |
| Primary keys | `PRIMARY KEY (...)`, composite keys in key order |
| Check constraints | `CONSTRAINT ... CHECK (...)`, with `NOT ENFORCED` where set. Empty on servers without check constraints (the version gate is `supports_check_constraints?`) |
| Indexes | Full definition: `UNIQUE`, `FULLTEXT`, `SPATIAL`, prefix lengths (`` `col`(10) ``), `DESC` key parts, functional key parts, `INVISIBLE` |
| Foreign keys | `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY (...) REFERENCES ... (...)`, identifiers quoted; a composite key is one statement listing its columns in key order |
| Views | `CREATE OR REPLACE VIEW ... AS` plus the query from `SHOW CREATE VIEW`, which does not qualify objects with the database name, so the dump loads into a database of any name. `WITH ... CHECK OPTION` is kept |
| Procedures, functions | `SHOW CREATE PROCEDURE / FUNCTION` with the `DEFINER` clause removed |
| Triggers | `SHOW CREATE TRIGGER` with the `DEFINER` clause removed. Triggers on the same table, timing and event are written in firing order (`ACTION_ORDER`), so a load keeps that order |
| Comments | Table comments as `ALTER TABLE ... COMMENT '...'`; column comments only as SQL comments |
| Migrations | `INSERT IGNORE INTO ...` |

No header is written.

MariaDB: a `JSON` column (stored by the server as `longtext` plus a `json_valid` check) is dumped as `json`.

### Loading a MySQL dump

Load through the gem: set `config.replace_default_load = true` (then `rails db:schema:load`, `db:setup` and `db:test:prepare` use it) or run `rails db:schema:load_better`.

Rails' own `structure.sql` load pipes the file through the `mysql` client, which needs `DELIMITER` directives around routine and trigger bodies. The dump has none: `SchemaLoader` splits statements itself (it tracks `BEGIN ... END` nesting) and sends them one by one over the ActiveRecord connection. While it does so, query transformers (Rails query log tags) are switched off, because MySQL would store a trailing comment as part of a routine or trigger body.

## SQLite

| Object | Output |
|---|---|
| PRAGMA settings | In the extensions section: only `application_id`, `auto_vacuum` and `user_version` (the settings stored in the database file), and each only when non-zero. Connection-scoped settings (`journal_mode`, `synchronous`, ...) are not part of the schema and are not dumped |
| Tables | The original `CREATE TABLE` statement from `sqlite_master`, verbatim. Everything in it survives: `AUTOINCREMENT`, `WITHOUT ROWID`, `STRICT`, collations, composite primary keys, generated columns, named and unnamed `CHECK` constraints, table-level `UNIQUE`, inline foreign keys (composite included). Formatting and quoting are those of the statement that created the table |
| Indexes | The original `CREATE INDEX` statement, partial and expression indexes included. Indexes SQLite creates implicitly for `PRIMARY KEY` / `UNIQUE` come back with their table |
| Views | The original `CREATE VIEW` statement (no `OR REPLACE`, which SQLite rejects) |
| Triggers | The stored `CREATE TRIGGER` statement |

Header: `PRAGMA foreign_keys = ON;`, `PRAGMA defer_foreign_keys = ON;`. No foreign keys section: the keys are part of each `CREATE TABLE`.

Migrations: `INSERT INTO "schema_migrations" ...`, as on the other adapters.

## Adding a capability

1. Implement `fetch_<objects>` on the adapter; order the result.
2. Set the `supports_*?` flag on all three adapters, or return an empty list where unsupported.
3. Add or extend the generator in `lib/better_structure_sql/generators/`.
4. Wire the section into both dump paths in [`dumper.rb`](../../lib/better_structure_sql/dumper.rb) and into `FileWriter::SECTION_DIRECTORIES`.
5. Add adapter and generator specs, and a load round-trip: the fixture of `spec/integration/postgresql_round_trip_spec.rb` on PostgreSQL, a migration in `integration_mysql/` or `integration_sqlite/` (checked by `bss:round_trip`) on the others.
