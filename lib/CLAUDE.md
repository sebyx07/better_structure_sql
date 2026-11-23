# lib/ — layers and ownership

Root `CLAUDE.md` has the invariants, the commands and the dump order table. This file: who owns what, and the rules that bite while writing code here.

Flow of one dumped object: **adapter -> Introspection -> Generator -> Dumper section -> FileWriter**. Adding or extending an object type: skill `add-schema-object`.

## Layer rules

| Layer | File(s) | Rule |
|---|---|---|
| Entry | `better_structure_sql.rb` | Requires everything eagerly except the three adapters' classes (`Registry` requires them on first use) and `railtie` / `engine` (only when Rails is defined). `BetterStructureSql.configure` / `.configuration` / `.reset_configuration` |
| Configuration | `better_structure_sql/configuration.rb` | New option: default in `initialize`, check in `validate!` (raise `ConfigurationError` with a fix hint), line in `lib/generators/better_structure_sql/templates/better_structure_sql.rb`, row in `docs/configuration.md` |
| Registry | `adapters/registry.rb` | Maps `connection.adapter_name` (`postgresql`, `postgis`, `mysql2`, `trilogy`, `sqlite3`) to an adapter; caches per connection object and override. Requires the MySQL / SQLite driver gem lazily and raises `Error` naming the gem. Specs that swap connections call `Registry.clear_cache!` |
| Adapters | `adapters/base_adapter.rb`, `adapters/{postgresql,mysql,sqlite}_adapter.rb`, `adapters/*_config.rb` | **All catalog SQL lives here.** `fetch_*(connection)` returns arrays of plain hashes with the same keys on every adapter; `supports_*?` states capability |
| Introspection | `introspection.rb`, `introspection/*.rb` | Facade only: each `fetch_*` delegates to `adapter_for(connection)`. No SQL, no rescue |
| Generators | `generators/*.rb` | Inherit `Generators::Base`, implement `generate(object)` -> one SQL string. Data in, text out: never a connection, never a query. `TableGenerator` alone also takes the adapter |
| Dumper | `dumper.rb` | Orchestrates; never writes SQL for an object itself except the header and the `schema_migrations` INSERT |
| Ordering | `creation_order.rb`, `dependency_resolver.rb` | See below |
| Formatter | `formatter.rb` | Presentation only (rstrip, collapse blank lines, section spacing). Single-file path only |
| FileWriter | `file_writer.rb` | `SECTION_DIRECTORIES`, chunking, atomic writes (temp file + rename), removal of stale files from a previous dump |
| Manifest | `manifest_generator.rb` | `_manifest.json`: totals and per-directory stats. Statistics only; the loader does not need it |
| Loader | `schema_loader.rb` | Pure-Ruby load of a file or directory: `_header.sql`, then numbered directories sorted by name, files sorted by name. Statement splitting is adapter-specific |
| ZIP | `zip_generator.rb` | In-memory rubyzip. Extraction enforces `MAX_FILES_IN_ZIP`, `MAX_UNCOMPRESSED_SIZE` and `safe_entry_path`. Loosening any of them needs a spec with a hostile archive |
| Versions | `schema_versions.rb`, `schema_version.rb`, `store_result.rb` | See below |
| Rails | `railtie.rb`, `migration_patch.rb`, `tasks/better_structure_sql.rake`, `generators/better_structure_sql/` | See below |
| Engine | `engine.rb` | Access-control registry; controllers in `app/` (`app/CLAUDE.md`) |

## Adapters

- One batched query per object type, never one per table. Build a lookup hash in Ruby.
- Every query ends in a stable `ORDER BY`, or the result is sorted in Ruby. Unordered rows = a dump that differs between runs, which no unit spec catches.
- Values go through `connection.quote`. Never interpolate a table, schema or column name taken from the database into SQL unquoted.
- PostgreSQL dumps one schema: `PostgresqlAdapter::DUMPED_SCHEMA` (`public`). Objects owned by an extension are excluded.
- Partitions are not top-level tables: each is nested under its parent's `:partitions`, so `TableGenerator` emits it after the parent.
- A capability added to one adapter: add `fetch_*` and `supports_*?` to `base_adapter.rb`, then on the other two either implement it or return `[]` with the flag false. Spec per adapter in `spec/adapters/`.
- Unsupported feature = empty section. Never SQL that the producing database cannot load.
- MySQL covers `mysql2`, `trilogy` and MariaDB (`mariadb?` gates version checks). SQLite has no foreign-key section (inline in `CREATE TABLE`) and no sequences, functions, custom types or materialized views.
- Other agents may be editing `mysql_adapter.rb` / `sqlite_adapter.rb`: run `git status` and `git diff <file>` before touching them.

## Generators

- Identifiers: `quote_identifier` (doubles embedded quote characters; backticks on MySQL) and `qualified_identifier` (omits default schemas). Do not hand-roll quotes.
- Output is byte-stable: no `Hash` iteration whose order comes from the database, no `Time.now`, no version text.
- The spec asserts the exact statement (`spec/generators/<name>_generator_spec.rb`).

## Dumper and ordering

- Two paths, one contract: `dump_single_file` joins `*_section` strings (with `-- Title` comments); `dump_multi_file` builds arrays from `generate_*_section`. Every object type appears in both.
- `CreationOrder.for(adapter, connection)` runs one `pg_depend` query on PostgreSQL and returns an empty order for other adapters (they keep the fixed order; MySQL orders its views in `fetch_views`). Keys: `relation:` (tables, views, matviews, sequences), `function:`, `type:` (enums, composites, ranges, domains).
- `type_statements`: custom types and domains that need no routine, one dependency-sorted list (`02_types`). `early_statements`: functions with no relation dependency plus the types that need a routine (a domain CHECK calling a function), dependency-sorted, written before tables (`03_functions`). `relation_dependent_statements`: views + materialized views + the remaining functions, topologically sorted by `DependencyResolver` into one sequence. Single-file output titles each run; multi-file puts the whole sequence in `08_views`.
- `DependencyResolver#resolve` returns best-effort order on a cycle (it does not raise).
- `Dumper#dump(store_version: nil)`: `nil` follows `config.enable_schema_versions`; storing failures propagate. Rake and the Rails dump hook pass `store_version: false`; storing is the explicit `db:schema:store`.
- `sort_tables` sorts by name; `ordered_tables` then defers an inheritance child (`:inherits`) to right after its last parent. SQLite tables are replayed verbatim from `sqlite_master` (`:sql`), foreign keys included.
- Multi-file skips `07_foreign_keys` on SQLite. Every adapter dumps the `schema_migrations` table and its INSERT; without them a loaded dump leaves every migration pending.

## Schema versions

- Table `better_structure_sql_schema_versions` (model `SchemaVersion`). `content_hash` is the MD5 of exactly the stored content.
- `SchemaVersions.store_current`: read the dump from disk -> hash -> **skip** when the latest version has the same hash -> else store, then retention `cleanup!`. Cleanup runs only after a real store, never on a skip. Returns `StoreResult` (`stored?` / `skipped?`).
- Multi-file: content is the concatenation in directory order, plus a ZIP of the directory. Storing never modifies the schema on disk.
- `SchemaVersions.restore(version, db_config:)` (task `db:schema:restore`, needs `CONFIRM=1`): purges the database, loads the version with `SchemaLoader`, records the environment. Stored versions in that database are lost.
- Changing what is hashed, or when cleanup runs, needs a spec (`spec/integration/schema_version_deduplication_spec.rb`).

## Rails integration

- `Railtie` always applies `MigrationPatch`: `check_schema_file`, `schema_sha1` and `structure_load` accept a schema directory. `maintain_test_schema!` calls Rails' own when either `replace_default_*` option is on (Rails then resolves the directory itself); otherwise it loads the directory at `output_path` through `DatabaseTasks.load_schema`, which records the environment and checksum, and checks pending migrations.
- `replace_default_dump` prepends onto `ActiveRecord::Tasks::DatabaseTasks`: `schema_dump_path` (primary database -> `config.output_path`; other databases keep the Rails path; `SCHEMA=` wins) and `dump_schema`. `replace_default_load` overrides `structure_load` with `SchemaLoader`. Both are skipped when `output_path` ends in `.rb`.
- These are prepends on Rails internals: a Rails upgrade can break them silently. The integration apps in CI are the check, not the unit specs.

## Errors

- Raise a class from `errors.rb`; `SchemaLoader::LoadError` and `ZipGenerator::ZipError` are the local ones.
- No new blanket rescue. The existing `rescue StandardError` site (`generators/base.rb` adapter detection) is debt, not a pattern to copy.
