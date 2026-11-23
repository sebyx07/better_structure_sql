---
name: add-schema-object
description: Use when adding or extending a database object type in the schema dump — a new generator, introspection query, dump section or adapter capability (e.g. partitions, rules, policies, comments, a MySQL or SQLite equivalent of a PostgreSQL feature).
---

# Add or extend a dumped object type

A dumped object flows adapter → introspection → generator → dumper section → file writer. Mirror the nearest existing type (triggers and comments are the most recent complete examples) at every stop.

1. **Spec first.** `spec/generators/<object>_generator_spec.rb`, mirroring `spec/generators/trigger_generator_spec.rb`: feed a plain hash, assert the exact SQL text.
2. **Generator.** `lib/better_structure_sql/generators/<object>_generator.rb` — inherits `Generators::Base`, implements `generate(object)`, returns one SQL string. Receives data, never a connection. Quote identifiers the way the neighbouring generators do.
3. **Adapter interface.** `lib/better_structure_sql/adapters/base_adapter.rb`: add `fetch_<objects>(connection)` and `supports_<objects>?`. Implement in `postgresql_adapter.rb`; in `mysql_adapter.rb` and `sqlite_adapter.rb` either implement or return `[]` with `supports_<objects>?` false. Specs in `spec/adapters/`.
4. **Introspection query.** Catalog queries live in the adapter (`lib/better_structure_sql/adapters/postgresql_adapter.rb`, and the MySQL/SQLite adapters for parity); `lib/better_structure_sql/introspection/<objects>.rb` only delegates `fetch_<objects>(connection)` to it. One batched query for all objects (never per table), `ORDER BY` a stable key — unordered rows make the dump non-deterministic.
5. **Config toggle.** `lib/better_structure_sql/configuration.rb`: `include_<objects>` beside the other `include_*` defaults, plus the initializer template under `lib/generators/better_structure_sql/templates/`.
6. **Dumper — both output paths.** `lib/better_structure_sql/dumper.rb` builds single-file output from `<objects>_section` and multi-file output from `generate_<objects>_section` inside `generate_sections_for_multi_file`. Add both, at the position the dependency order requires (extensions → types → functions → sequences → tables → indexes → foreign keys → views → triggers → comments → migrations).
7. **Multi-file directory.** New section key → add it to `SECTION_DIRECTORIES` in `lib/better_structure_sql/file_writer.rb`; the numeric prefix is the load order `SchemaLoader` and the manifest follow.
8. **Prove it.** `bin/check files <every file you touched>`; then against a real database: add a migration using the feature under `integration/db/migrate/`, `bin/dev --detach`, and confirm two consecutive `cd integration && bin/rails db:schema:dump_better` runs leave `git status integration/db/schema` identical. `bin/stop`.
9. **Docs.** `CHANGELOG.md` under `## [Unreleased]`; the feature tables in `README.md`; the matching page under `docs/` and `site/src/pages/` when one exists.

Fail → stop: a feature one adapter cannot express degrades to an empty section and a logged warning, never to invalid SQL for that database.
