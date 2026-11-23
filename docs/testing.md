# Testing

## Run

```bash
bin/setup                                  # once: gems, PostgreSQL, test database
bin/check                                  # rubocop + full rspec (the CI gate)
bin/check fast                             # rubocop on changed files + specs that need no database
bin/check files spec/formatter_spec.rb     # only the named files
```

`bin/check` uses `DATABASE_URL` when exported, otherwise the PostgreSQL container `bin/setup` starts. Exit 75 means the environment is missing (run `bin/setup`); exit 1 means a check failed, and the output names the command to rerun.

Direct commands, when you need RSpec options:

```bash
RAILS_ENV=test DATABASE_URL=postgresql://... bundle exec rspec spec/adapters
bundle exec rubocop
```

## Layout

| Path | Covers | Needs a database |
|---|---|---|
| `spec/configuration_spec.rb`, `spec/formatter_spec.rb` | Configuration validation, formatting | no |
| `spec/generators/` | One spec per SQL generator, fed plain hashes | no |
| `spec/adapters/` | Adapter introspection and the registry, on stubbed connections; the SQLite adapter also on a real in-memory database | no |
| `spec/better_structure_sql/` | File writer, manifest, schema versions, store result | specs that load `rails_helper` do |
| `spec/controllers/`, `spec/helpers/`, `spec/routing/` | Web UI engine | yes |
| `spec/integration/` | Edge cases, schema version deduplication and validations | specs that load `rails_helper` do |
| `spec/integration/postgresql_round_trip_spec.rb` | The PostgreSQL round trip (below) | PostgreSQL only |
| `spec/factories/`, `spec/fixtures/` | FactoryBot factories, SQL fixtures | - |

`spec/spec_helper.rb` loads the gem without Rails. `spec/rails_helper.rb` boots a minimal Rails application, connects, and creates the schema versions table; a spec that requires it needs the database.

## Writing specs

| Change | Spec to add |
|---|---|
| New or changed generator output | `spec/generators/<name>_generator_spec.rb`: assert the exact SQL string |
| Adapter query or capability flag | `spec/adapters/<db>_adapter_spec.rb`; keep the three adapters' `supports_*?` flags consistent |
| PostgreSQL feature end to end | `spec/fixtures/postgresql_round_trip.sql` and `spec/integration/postgresql_round_trip_spec.rb` |
| MySQL or SQLite behaviour | The adapter spec, plus a migration in `integration_mysql/` or `integration_sqlite/` so `bss:round_trip` covers it |
| Section order, chunking, directory names | `spec/better_structure_sql/file_writer_spec.rb` and a load round-trip in `spec/integration/` |
| Schema version storage, hashing, retention | `spec/better_structure_sql/schema_versions_spec.rb` or `spec/integration/` |
| Web UI | `spec/controllers/better_structure_sql/`; include the access-control cases |

Rules:

- Assert whole statements, not substrings, when the output format is the contract.
- Determinism is a feature: dump twice and compare when ordering is involved.
- Generated SQL must load back. Prefer a dump, load, dump round-trip over inspecting text.

## Round trip

The strongest check the project has: dump, load the dump into an empty database, dump again. The two dumps must be byte-identical and the database must report the same objects on both sides, which catches objects lost or altered identically in both dumps.

| Database | Where | Compares |
|---|---|---|
| PostgreSQL | `spec/integration/postgresql_round_trip_spec.rb`, fixture `spec/fixtures/postgresql_round_trip.sql`. Part of `bin/check`; it drops and creates `<database>_round_trip_source` / `_round_trip_target` | Dumps, plus the catalogs |
| MySQL, MariaDB | `bss:round_trip` in `integration_mysql/` ([`lib/tasks/round_trip.rake`](../integration_mysql/lib/tasks/round_trip.rake)) | Dumps, plus `SHOW CREATE` of every table, view, routine and trigger |
| SQLite | `bss:round_trip` in `integration_sqlite/` ([`lib/tasks/round_trip.rake`](../integration_sqlite/lib/tasks/round_trip.rake)) | Dumps, plus `sqlite_master` |

`bss:round_trip` dumps the migrated development database, purges the test database, loads the dump into it with `SchemaLoader` and dumps again. Output and, on failure, the files to diff are in `tmp/round_trip/`.

```bash
cd integration_sqlite && bundle exec rake db:create db:migrate bss:round_trip
cd integration_mysql  && DB_ADAPTER=trilogy bin/rails db:create db:migrate bss:round_trip   # DB_ADAPTER: mysql2 (default) or trilogy
ROUND_TRIP_LAYOUT=multi_file bin/rails bss:round_trip                                      # directory layout instead of a single file
```

The MySQL app reads `DB_HOST`, `DB_PORT`, `DB_USERNAME` and `DB_PASSWORD` (see its `config/database.yml`).

## Integration apps

| App | Database | Use |
|---|---|---|
| `integration/` | PostgreSQL | `bin/dev` boots it; exercises every PostgreSQL feature and the web UI. CI migrates it from scratch, loads the dump into an empty database and dumps again |
| `integration_mysql/` | MySQL, MariaDB | The same migrate / load / dump cycle through `rails db:schema:load`, then `bss:round_trip` in both layouts |
| `integration_sqlite/` | SQLite | Migrate, dump, then `bss:round_trip` in both layouts |

They are separate Rails applications with their own `Gemfile`; they are not part of `bin/check`.

## CI

[`.github/workflows/ci.yml`](../.github/workflows/ci.yml) is the source of truth for the versions tested. Besides rubocop and the spec suite, it runs all three integration apps (`integration-postgresql`, `integration-mysql`, `integration-sqlite`); the database servers and MySQL drivers each one runs against are the matrix of its job.
