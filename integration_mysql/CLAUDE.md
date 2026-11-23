# integration_mysql/ (MySQL and MariaDB app)

A minimal Rails app that uses the gem from the checkout (`path: '..'`, own `Gemfile` and lockfile) to dump
and load a MySQL or MariaDB schema through `mysql2` or `trilogy` (`DB_ADAPTER`).

## Run it

- `bin/check` does **not** run this app. CI does, in the `integration-mysql` job of `.github/workflows/ci.yml`
  (servers and adapters are its matrix; do not restate them): migrate from scratch, schema load and dump,
  then `bin/rails bss:round_trip` for the single-file and the multi-file layout.
- `bss:round_trip` (`lib/tasks/round_trip.rake`) dumps development, loads the dump into a fresh test
  database, dumps again and fails unless the two dumps are byte-identical and `SHOW CREATE` output matches.
- Locally: point `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD` at a server (`config/database.yml`),
  then run the same commands as the CI job. `docker compose -f docker-compose.mysql.yml up mysql` at the root
  starts one on 127.0.0.1:3306 (root password `password`).

## Rules

- No extensions, custom types, domains, sequences or materialized views on MySQL. Foreign keys are a
  separate section, as on PostgreSQL; only SQLite inlines them.
- View, routine and trigger definitions come from `SHOW CREATE ...`; the object list from `information_schema`.
- `db/schema/` and `db/structure.sql` are gem output, never edited by hand.
