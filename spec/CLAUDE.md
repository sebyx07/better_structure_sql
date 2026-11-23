# spec/ — RSpec

Root `CLAUDE.md` has the commands. This file: which database a spec runs on, what each directory proves, and what must never be mocked.

## Which database

| How you run | Database | Notes |
|---|---|---|
| `bin/check`, `bin/check files <spec>` | PostgreSQL: `DATABASE_URL` if exported, else `bss-pg` at `127.0.0.1:55432/better_structure_sql_test` | The gate |
| `BSS_TEST_DB=<name> bin/check ...` | Private database `<name>` on the same server, created on first use | Ignored when `DATABASE_URL` is exported |
| bare `bundle exec rspec` | In-memory SQLite from `config/database.yml` | PostgreSQL-only specs **skip**, they do not fail |
| `bin/check fast` | none | Only specs that do not load `rails_helper`, and nothing under `spec/integration/` |

- CI runs the suite both ways: PostgreSQL and the SQLite default (`locked` job in `.github/workflows/ci.yml`). A spec that loads `rails_helper` must pass on both, or skip itself explicitly with a reason when it needs PostgreSQL.
- **Green on SQLite proves nothing about the PostgreSQL dump.** After touching `lib/`, run on PostgreSQL.
- **Shared checkout = private database.** `rails_helper` truncates every table before the suite, and the round-trip spec drops and creates `<database>_round_trip_source` / `_round_trip_target`. Two agents on one database corrupt each other's runs: each sets its own `BSS_TEST_DB`.
- Exit 75 from `bin/check` = no database or no bundle. Nothing ran. `bin/setup`.

## Helpers

| File | Loads | Use for |
|---|---|---|
| `spec_helper.rb` | The gem, no Rails app, no connection | Generators, configuration, formatter, adapters on stubbed connections, pure classes |
| `rails_helper.rb` | A minimal Rails app (`Dummy::Application`), the connection from `config/database.yml` or `DATABASE_URL`, the engine, a freshly created `better_structure_sql_schema_versions` table, DatabaseCleaner, FactoryBot | Anything touching ActiveRecord, the engine or the dumper |

- `.rspec` requires `spec_helper` for every file; a spec needing the database requires `rails_helper` itself. That `require` line is what `bin/check fast` greps for.
- DatabaseCleaner: transaction per example, truncation for `type: :controller`.
- Random order, `verify_partial_doubles`, `disable_monkey_patching!` (write `RSpec.describe`). Failures persist in `spec/examples.txt` for `--only-failures`.
- `spec/dummy/` holds only a README; the app under test is built in `rails_helper.rb`. The full Rails apps are `integration*/` at the repo root.

## Layout

| Path | Proves | Database |
|---|---|---|
| `generators/` | Exact SQL text per object type, from plain hashes | no |
| `adapters/` | Queries and `supports_*?` flags. PostgreSQL and MySQL on stubbed connections; `sqlite_adapter_spec.rb` also on a real in-memory SQLite | no |
| `configuration_spec.rb`, `formatter_spec.rb`, `better_structure_sql_spec.rb` | Validation, formatting, module API | no |
| `better_structure_sql/` | Dumper, creation order, file writer, manifest, loader, ZIP, schema versions, railtie | most do |
| `integration/postgresql_round_trip_spec.rb` | The oracle (below) | PostgreSQL only |
| `integration/` (others) | Deduplication, validations, edge cases | yes |
| `controllers/`, `requests/`, `routing/`, `helpers/` | Engine, including the denied-access cases | yes |
| `tasks/` | Rake tasks against a temp `Rails.root` | yes |
| `factories/`, `fixtures/` | `schema_versions` factory; `postgresql_round_trip.sql` | - |

## The round-trip oracle

`integration/postgresql_round_trip_spec.rb` loads `fixtures/postgresql_round_trip.sql` into a source database, dumps it, executes the dump in an empty target database and dumps again. It asserts:

1. the load succeeds,
2. both dumps are **byte-identical**,
3. a catalog fingerprint (columns, constraints, indexes, partitions, sequences, triggers, routines, views, enums, ranges, domains, ...) is equal in both databases,
4. the same for a multi-file dump loaded by `SchemaLoader` in directory order.

Rules:

- New or changed PostgreSQL output: add the feature to the fixture first, watch the spec fail, then fix `lib/`.
- A feature the fingerprint cannot see is not covered: extend `catalog_fingerprint_sql` too.
- Never edit the expected side to match a diff you have not explained. When the two dumps differ, the dump is wrong.
- Never stub the connection, `Introspection` or an adapter here or anywhere in `integration/`.
- It skips without PostgreSQL. A run where it was skipped does not count as verification; say so in the PR.

## Writing specs

| Change | Spec |
|---|---|
| Generator output | `generators/<name>_generator_spec.rb`: assert the whole statement, not a substring |
| Adapter query or flag | `adapters/<db>_adapter_spec.rb`; keep the three adapters' flags consistent |
| PostgreSQL feature end to end | fixture + round-trip spec |
| Section order, chunking, directory names | `better_structure_sql/file_writer_spec.rb` + round-trip |
| Function / view ordering | `better_structure_sql/creation_order_spec.rb` + round-trip |
| Storage, hashing, retention | `better_structure_sql/schema_versions_spec.rb`, `integration/schema_version_deduplication_spec.rb` |
| Web UI | `controllers/better_structure_sql/`, `requests/better_structure_sql/engine_spec.rb` |
| MySQL or SQLite behaviour | adapter spec, plus a migration in `integration_mysql/` or `integration_sqlite/` (CI runs `bss:round_trip` there: dump, load, dump, compare) |

- Determinism: dump twice and compare whenever ordering is involved.
- Prefer dump -> load -> dump over inspecting text.
- Temp output goes in `Dir.mktmpdir`, removed in `after`. Never write into the repo's `db/`.
- No new `skip` without a reason that names the missing prerequisite. Never delete or skip a failing spec to get green.
- Specs that change global state restore it: `BetterStructureSql.reset_configuration`, `Adapters::Registry.clear_cache!`, `Engine.reset_authentication!`.
