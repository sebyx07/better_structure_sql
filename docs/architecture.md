# Architecture

How a dump is produced, and which file owns each step.

## Flow

```
rake db:schema:dump_better
        │
        ▼
Dumper ──► Adapters::Registry ──► PostgresqlAdapter | MysqlAdapter | SqliteAdapter
  │                                   (introspection: fetch_* → arrays of hashes)
  ├──► Generators::*  (hash → SQL string, one class per object type)
  ├──► Formatter      (single file: whitespace and section spacing)
  ├──► FileWriter     (single file, or numbered directories with chunking)
  ├──► ManifestGenerator (multi-file: _manifest.json)
  └──► SchemaVersions (optional: store the result)
```

Loading is the reverse and much smaller: `SchemaLoader` executes a file, or a directory's files in sorted order.

## Components

| Component | File | Responsibility |
|---|---|---|
| Configuration | `lib/better_structure_sql/configuration.rb` | Options, defaults, `validate!` |
| Registry | `lib/better_structure_sql/adapters/registry.rb` | Pick and cache the adapter for a connection |
| Adapters | `lib/better_structure_sql/adapters/*_adapter.rb` | Catalog queries, `supports_*?` flags, database version |
| Introspection | `lib/better_structure_sql/introspection/` | Thin facade: `Introspection.fetch_tables(connection)` delegates to the adapter chosen by `config.adapter` |
| Generators | `lib/better_structure_sql/generators/` | One class per object type; `generate(hash)` returns SQL |
| Dumper | `lib/better_structure_sql/dumper.rb` | Section order, single-file and multi-file paths |
| Formatter | `lib/better_structure_sql/formatter.rb` | Trailing whitespace, collapsed blank lines, section spacing |
| FileWriter | `lib/better_structure_sql/file_writer.rb` | Output mode, directory names, chunking, stale-file removal |
| ManifestGenerator | `lib/better_structure_sql/manifest_generator.rb` | `_manifest.json` statistics |
| SchemaLoader | `lib/better_structure_sql/schema_loader.rb` | Execute a file or directory against the connection |
| SchemaVersions | `lib/better_structure_sql/schema_versions.rb` | Store, deduplicate, query, retention |
| SchemaVersion | `lib/better_structure_sql/schema_version.rb` | ActiveRecord model for the versions table |
| StoreResult | `lib/better_structure_sql/store_result.rb` | Stored-or-skipped value object |
| ZipGenerator | `lib/better_structure_sql/zip_generator.rb` | Create, validate and extract ZIP archives |
| Railtie | `lib/better_structure_sql/railtie.rb` | Rake tasks; replaces Rails dump/load when configured |
| MigrationPatch | `lib/better_structure_sql/migration_patch.rb` | Makes a schema directory work where Rails expects a file |
| Engine | `lib/better_structure_sql/engine.rb`, `app/`, `config/routes.rb` | Web UI and its access control |
| Rails generators | `lib/generators/better_structure_sql/` | `install` and `migration` |
| Rake tasks | `lib/tasks/better_structure_sql.rake` | `db:schema:*` |

## Contracts

| Contract | Where it lives | Breaks when |
|---|---|---|
| Section order: extensions, types, domains, functions, sequences, tables, indexes, foreign keys, views, materialized views, triggers, comments, migrations | `Dumper` (both dump paths) and `FileWriter::SECTION_DIRECTORIES` | The two disagree: a multi-file dump loads in a different order than a single-file one |
| Directory prefix = load order | `FileWriter`, `SchemaLoader` | A directory is renamed without updating the loader's glob |
| Deterministic output | Adapter queries are ordered; chunking depends only on content | A query returns catalog order, or output includes a timestamp or server version |
| Adapters return plain hashes | `BaseAdapter` documents the keys | A generator receives a connection or runs a query |
| Generators are pure | `Generators::Base` | A generator depends on dump order or global state |
| Content hash = MD5 of exactly the stored `content` | `SchemaVersions` | The hashed text and the stored text diverge: deduplication stops working |
| Web UI fails closed | `BetterStructureSql::ApplicationController#authenticate_access!` | A controller skips the `before_action` |

## Adapter interface

`BaseAdapter` ([source](../lib/better_structure_sql/adapters/base_adapter.rb)) defines:

| Group | Methods |
|---|---|
| Introspection | `fetch_extensions`, `fetch_custom_types`, `fetch_tables`, `fetch_indexes`, `fetch_foreign_keys`, `fetch_views`, `fetch_materialized_views`, `fetch_functions`, `fetch_sequences`, `fetch_triggers`, `fetch_comments` |
| Capabilities | `supports_extensions?`, `supports_materialized_views?`, `supports_custom_types?`, `supports_domains?`, `supports_functions?`, `supports_triggers?`, `supports_sequences?`, `supports_comments?` |
| Version | `database_version`, `parse_version`, `version_at_least?` |

Tables are fetched in batches (all columns, all constraints in one query each), not per table. PostgreSQL views are ordered with `DependencyResolver` (`lib/better_structure_sql/dependency_resolver.rb`), a topological sort over view-to-view dependencies; other sections are ordered by name. An introspection error raises; it is not turned into an empty section.

What each adapter returns: [features/multi-database.md](features/multi-database.md).

## Rails integration

| Hook | Effect |
|---|---|
| `rake_tasks` | Loads `lib/tasks/better_structure_sql.rake` |
| `replace_default_dump` | Prepends to `ActiveRecord::Tasks::DatabaseTasks` so the SQL-format dump goes through `Dumper`; sets the schema format to `:sql` |
| `replace_default_load` | Prepends so the SQL-format load goes through `SchemaLoader` |
| `MigrationPatch.apply!` | Always applied. `DatabaseTasks`: the schema checksum, the schema-file check and `structure_load` accept a directory (`structure_load` hands it to `SchemaLoader`). `maintain_test_schema!`: delegates to Rails when a `replace_default_*` option is on; otherwise loads the directory at `output_path` through Rails' `load_schema` and checks pending migrations. `maintain_test_schema = false` is respected |

## Not wired in

| Item | State |
|---|---|
| `Adapters::MysqlConfig`, `Adapters::SqliteConfig`, `Adapters::PostgresqlConfig` | Settings objects; nothing reads the MySQL and SQLite ones, and the PostgreSQL one is empty. |
| `Configuration#schemas`, `#include_rules` | Validated, not used. See [configuration.md](configuration.md#options-with-no-or-partial-effect). |

## Security boundaries

| Boundary | Rule |
|---|---|
| Introspection SQL | Identifiers and values go through `connection.quote` / `quote_table_name` |
| ZIP extraction | An entry that resolves outside the target directory raises `ZipError`; file count and inflated size are capped |
| Web UI | Access check on every request; content escaped; `no-store` responses |
| Dump content | Structure only: no table data, no credentials |
