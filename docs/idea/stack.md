# Stack

- **Gem:** Ruby, on Rails (ActiveRecord, Railtie, a mountable engine). Runtime dependencies are
  in `better_structure_sql.gemspec`: `rails`, `pg` and `rubyzip`. The MySQL drivers (`mysql2`,
  `trilogy`) and `sqlite3` are the host app's choice, required lazily by
  `lib/better_structure_sql/adapters/registry.rb`.
- **Versions:** the dev Ruby is `.ruby-version` (read by `mise.toml` and CI); the Ruby and Rails
  floors are in the gemspec; the tested Ruby, Rails and database versions are the matrices in
  `.github/workflows/ci.yml` and nowhere else.
- **Tests:** RSpec (`spec/`), with FactoryBot and DatabaseCleaner. Unit specs need no database;
  the rest run on a real PostgreSQL, and again on in-memory SQLite in CI. Three Rails apps
  (`integration/`, `integration_mysql/`, `integration_sqlite/`) dump and load through the gem in
  CI.
- **Lint:** RuboCop with the rspec, rails and performance plugins (`.rubocop.yml`). There is no
  type checker.
- **Gate:** `bin/check` locally (repo guards, RuboCop, full RSpec on PostgreSQL; exit 75 means the
  environment is missing and nothing was graded) and the `CI OK` job in
  `.github/workflows/ci.yml`, which runs the same `bin/check` plus the version matrix, the
  integration apps, the package build and workflow lint.
- **Local database:** `bin/setup` starts PostgreSQL in a Docker container, or uses
  `DATABASE_URL`.
- **Docs site:** React, React Router and esbuild in `site/`, with ESLint and Vitest; Node from
  `site/.nvmrc`.

Exact versions are in `Gemfile.lock` and `site/package-lock.json`; Dependabot keeps them current
(`.github/dependabot.yml`).
