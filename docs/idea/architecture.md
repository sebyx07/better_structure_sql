# Architecture

> established by the developerz.ai maintainer agent for the maintainers of this repository from what onboarding read and ran in this repo, then owned by
> its maintainers. Correct it in place; setup never overwrites a page that exists.

Flow: **adapter -> Introspection -> Generator -> Dumper -> FileWriter**. Each layer is independent; one reason to change per class.

`Adapters`: catalog queries (one per object type, ordered or sorted in Ruby), quote identifiers and values. `PostgresqlAdapter` (primary), `MysqlAdapter` (mysql2, trilogy, MariaDB), `SqliteAdapter` (original CREATE TABLE statements).

`Introspection`: thin facade, delegates to adapter, no SQL.

`Generators`: one class per object type (table, index, trigger, function, view, type, etc.). `generate(hash)` returns SQL string. No connection, no network.

`Dumper`: orchestrates. Calls adapters to fetch objects, generators to format them, writes sections in fixed order: header, extensions, types, functions, sequences, tables, indexes, foreign keys, views, triggers, comments, migrations.

`FileWriter`: writes single file (concatenated sections with comments) or multi-file (numbered directories, chunked by object count). Atomic writes (temp file + rename).

`SchemaLoader`: pure-Ruby load from file or directory. Respects section order and directory numbering.

`SchemaVersions`: stores dumped schema in database (MD5 dedup, retention cleanup). `StoreResult` distinguishes stored vs. skipped.

`CreationOrder` / `DependencyResolver`: topological sort for PostgreSQL types, domains, functions, views, materialized views. Other adapters keep fixed order. No cycles: returns best-effort order.

Read `lib/CLAUDE.md` for per-layer rules, adapter batching, quoting.
