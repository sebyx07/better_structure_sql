# integration_sqlite/ (SQLite app)

A minimal Rails app (no `bin/`, run tasks with `bundle exec rake`) that uses the gem from the checkout
(`path: '..'`, own `Gemfile` and lockfile) to dump and load a SQLite schema. Databases are files under `db/`.

## Run it

- `bin/check` does **not** run this app. CI does, in the `integration-sqlite` job of `.github/workflows/ci.yml`:
  `bundle exec rake db:create db:migrate db:schema:dump_better`, then `bundle exec rake bss:round_trip`,
  once as a single file and once with `ROUND_TRIP_LAYOUT=multi_file`.
- `bss:round_trip` (`lib/tasks/round_trip.rake`) dumps development, loads the dump into a purged test
  database, dumps again and fails unless both dumps are byte-identical and `sqlite_master` matches.

## Rules

- Output goes to `db/structure/` (multi-file; `config/initializers/better_structure_sql.rb`). The initializer
  turns off functions, sequences, domains, custom types and materialized views: SQLite has none.
- Tables come from the original `CREATE TABLE` text in `sqlite_master`, so foreign keys stay inline and
  there is no foreign key section.
- Dump files under `db/` are gem output, never edited by hand.
