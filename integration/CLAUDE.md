# integration/ (PostgreSQL app)

A minimal Rails app that uses the gem from the checkout (`gem 'better_structure_sql', path: '..'`, own
`Gemfile` and lockfile) to dump and load a real PostgreSQL schema, and hosts the engine's web UI.

## Run it

- `bin/dev [--detach]` from the repo root boots it on http://127.0.0.1:3000 against the `bss-pg` container;
  `bin/stop` stops it. `bin/dev` ignores `DATABASE_URL`.
- `bin/check` does **not** run this app. CI does, in the `integration-postgresql` job of
  `.github/workflows/ci.yml`: migrate from scratch (dumping to `db/schema/` through the gem), then
  `db:drop db:create db:schema:load db:schema:dump` with `REPLACE_DEFAULT_DUMP` / `REPLACE_DEFAULT_LOAD` set.
- There is no `bss:round_trip` task here: the PostgreSQL round-trip oracle is
  `spec/integration/postgresql_round_trip_spec.rb` at the root.

## Rules

- Connection from `config/database.yml`: `DB_ADAPTER`, `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`,
  `DB_NAME`, `DB_TEST_NAME`. Gem options from env in `config/initializers/better_structure_sql.rb`
  (`MULTI_FILE_SCHEMA`, `SCHEMA_OUTPUT_PATH`, `INCLUDE_*`, `REPLACE_DEFAULT_*`, ...).
- `db/schema/` and `db/structure.sql` are gem output: regenerate them with a dump, never edit them by hand.
- A schema feature added here also belongs in the root round-trip fixture (`spec/fixtures/postgresql_round_trip.sql`).
