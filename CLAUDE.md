# CLAUDE.md

Guidance for agents in this repository. **Budget: under 12,000 chars** (the developerz.ai loader keeps only the first 12,000). Move detail down, never raise the cap:

| Touching | Also read (auto-loads there) |
|---|---|
| `lib/` | [`lib/CLAUDE.md`](lib/CLAUDE.md): layer ownership, dump contract, adapter rules |
| `spec/` | [`spec/CLAUDE.md`](spec/CLAUDE.md): database isolation, helpers, round-trip spec |
| `.github/`, `RELEASE.md`, `lib/better_structure_sql/version.rb` | [`.github/CLAUDE.md`](.github/CLAUDE.md): CI jobs, canary, release lane |
| `app/`, `config/routes.rb` | [`app/CLAUDE.md`](app/CLAUDE.md): engine access control, escaping |

`AGENTS.md` is a symlink to this file. User-facing reference: `README.md`, `docs/`, `llms.txt`.

## better_structure_sql

Ruby gem (`better_structure_sql.gemspec`; version in `lib/better_structure_sql/version.rb`) that writes a clean `db/structure.sql`, or a directory of small numbered SQL files, for a Rails app by reading the database catalog over the ActiveRecord connection. Optional: schema versions stored in the database (MD5 dedup, retention) and a mountable engine to browse them.

Invariants, all must stay true:

1. **Pure Ruby.** Never shell out to `pg_dump`, `mysqldump`, `sqlite3`, `psql` or any binary.
2. **Deterministic.** Same schema = byte-identical dump on every run, machine and server version. Every introspected list has an `ORDER BY` or a Ruby sort; no timestamps, no version comments, no hash-order iteration.
3. **Round trip.** dump -> load into an empty database -> dump is byte-identical and the catalogs match. Oracle: `spec/integration/postgresql_round_trip_spec.rb` (fixture `spec/fixtures/postgresql_round_trip.sql`). A new PostgreSQL feature is not done until the fixture has it and the spec is green.
4. **Structure only.** Never dump or store table data, sequence values or credentials. The one exception is the `schema_migrations` version list.
5. **Quoted SQL.** Values reach introspection queries through `connection.quote`; generated identifiers go through `Generators::Base#quote_identifier`. No raw interpolation of names or values.
6. **Adapters.** PostgreSQL is the primary target; its round-trip oracle is the spec above. MySQL (`mysql2`, `trilogy`, MariaDB) and SQLite: adapter specs plus `bss:round_trip` in their integration app, run by CI. `pg` is a hard gemspec dependency; the MySQL and SQLite drivers are required lazily by `Adapters::Registry`, which raises with install instructions.

Floors (Ruby, Rails) live in the gemspec; the dev Ruby is `.ruby-version`. Tested versions live in `.github/workflows/ci.yml`. Never restate them in docs.

## Never

- Use git worktrees. Work in this checkout; parallel agents split into disjoint file sets.
- `git add -A` / `git add .` / `git stash`. Stage by path: the tree may hold another agent's work.
- `gem push`, `rake release`, or create a `v*` tag by hand. Release = merge a `version.rb` bump (`RELEASE.md`).
- Swallow errors: no blanket `rescue StandardError` / `rescue => e` that returns `[]`, `nil` or logs and continues. A dump silently missing objects is worse than a failed dump. Rescue the specific class, or let it raise.
- Add backwards-compat shims, deprecated aliases, dead-code comments or speculative abstractions.
- Mock the database in `spec/integration/` or the round-trip spec.
- Hardcode version matrices (Ruby, Rails, PostgreSQL, MySQL) in docs, README or comments. Point at `ci.yml`.
- Change the section order in one place only (see Dump order).
- Weaken the gate (rubocop config, `skip`, deleting a failing spec) to get green.
- Merge a breaking change without the owner's decision.

## Commands

| Task | Command |
|---|---|
| Install | `bin/setup`: Ruby, both bundles (gem + `integration/`), PostgreSQL, test database. Idempotent. Uses `DATABASE_URL` if exported, else docker container `bss-pg` on `127.0.0.1:55432` |
| Pre-PR gate | `bin/check`: rubocop + full rspec on PostgreSQL. Same commands CI runs |
| Inner loop | `bin/check fast`: rubocop on files changed vs `origin/main` + specs that need no database. Skips every spec that loads `rails_helper` and all of `spec/integration/` |
| Named files | `bin/check files <paths>`: rubocop on the Ruby ones, rspec on the `*_spec.rb` ones. |
| Private database | `BSS_TEST_DB=<name> bin/check ...`: own database on the `bss-pg` server, created on first use. Required when agents share a checkout: the suite truncates tables and the round-trip spec drops and creates databases |
| Single spec | `bin/check files spec/path_spec.rb`, or `RAILS_ENV=test DATABASE_URL=postgresql://... bundle exec rspec spec/path_spec.rb:LINE` |
| Rerun failures, lint fix | `bundle exec rspec --only-failures`, `bundle exec rubocop -a <file>` |
| Web UI | `bin/dev [--detach]`: boots `integration/` on http://127.0.0.1:3000/better_structure_sql/schema_versions (ignores `DATABASE_URL` on purpose) |
| Stop | `bin/stop [--keep-db]`: stops the `bin/dev` server and the container only if `bin/setup` started it |
| Integration apps | `integration/` (PostgreSQL), `integration_mysql/`, `integration_sqlite/`: separate Rails apps, own Gemfile. Not in `bin/check`; CI runs them (steps: the `integration-*` jobs in `.github/workflows/ci.yml`) |
| Docs site | `cd site && npm ci && npm run lint && npm test && npm run build` (Node from `site/.nvmrc`) |
| Release | Merge a `lib/better_structure_sql/version.rb` bump to `main` (`RELEASE.md`, `/release`) |

**Exit codes:** 0 green. **75 = environment missing (Ruby, gems, docker, PostgreSQL): nothing was graded.** Run `bin/setup` and rerun; never report 75 as a failing change, never as a pass. Anything else: a check ran and is red.

Changed `Gemfile`, the gemspec or a lockfile: `bin/setup` before `bin/check`.

## Architecture

One reason to change per class. Flow: **adapter -> Introspection -> Generator -> Dumper section -> FileWriter**. Detail and rules per layer: `lib/CLAUDE.md`.

| Layer | Path under `lib/better_structure_sql/` | Owns |
|---|---|---|
| Configuration | `configuration.rb` | Settings, `include_*` toggles, `validate!` (raises `ConfigurationError`) |
| Adapters | `adapters/registry.rb`, `adapters/{base,postgresql,mysql,sqlite}_adapter.rb` | All catalog queries, `supports_*?` flags, per-connection adapter cache |
| Introspection | `introspection.rb`, `introspection/` | Thin facade: `fetch_*(connection)` delegates to the adapter. Errors propagate |
| Generators | `generators/` | One class per object type; `generate(hash)` returns SQL. Receive data, never a connection |
| Dumper | `dumper.rb` | Orchestration, section order, single-file and multi-file paths |
| Ordering | `creation_order.rb`, `dependency_resolver.rb` | `CreationOrder` reads `pg_depend` (PostgreSQL only) and sorts types, functions, views and materialized views through `DependencyResolver` (topological sort) |
| Formatter | `formatter.rb` | Trailing whitespace, blank-line collapse, section spacing |
| Files | `file_writer.rb`, `manifest_generator.rb`, `schema_loader.rb`, `zip_generator.rb` | Numbered directories, chunking, atomic writes, `_manifest.json`, pure-Ruby load, ZIP with bomb and traversal limits |
| Versions | `schema_versions.rb`, `schema_version.rb`, `store_result.rb` | Store with MD5 dedup, retention cleanup only after a real store, `StoreResult` (stored or skipped) |
| Rails | `railtie.rb`, `migration_patch.rb`, `lib/tasks/better_structure_sql.rake`, `lib/generators/` | Replaces `db:schema:dump` / `db:schema:load` when configured, directory schemas in `maintain_test_schema!`, tasks `db:schema:{dump_better,load_better,store,versions,cleanup,restore}`, generators |
| Engine | `engine.rb`, `app/`, `config/routes.rb` | Web UI. **Fails closed**: outside development and test every request is 403 until the host calls `Engine.authenticate_with` or `Engine.authentication_handled_by_routes!` |

Errors: raise a class from `errors.rb` (`ConfigurationError`, `SchemaVersionError`, ...), with a message that says what to do.

## Dump order (a contract, three places)

As `Dumper` writes it. The numbered directory is `FileWriter::SECTION_DIRECTORIES`; its prefix is the load order `SchemaLoader` follows.

| # | Section | Multi-file directory |
|---|---|---|
| 0 | Header (`SET ...` on PostgreSQL, `PRAGMA` on SQLite), then `SET search_path` on PostgreSQL | `_header.sql` |
| 1 | Extensions | `01_extensions` |
| 2 | Enums, composites, ranges and domains that need no function, dependency-sorted | `02_types` |
| 3 | Functions that need no relation (table defaults, checks and indexes may call them) and the types that need one of them, dependency-sorted | `03_functions` |
| 4 | Sequences | `04_sequences` |
| 5 | Tables (sorted by name; partitions nested after their parent; inheritance children after their parents) | `05_tables` |
| 6 | Indexes | `06_indexes` |
| 7 | Foreign keys (SQLite: inline in `CREATE TABLE`, no section) | `07_foreign_keys` |
| 8 | Views, materialized views and relation-dependent functions, as **one** dependency-sorted sequence | `08_views` |
| 9 | Triggers | `09_triggers` |
| 10 | Comments | `10_comments` |
| 11 | `schema_migrations` INSERT | `20_migrations` |

- Single-file builds from `*_section` methods, multi-file from `generate_*_section` in `generate_sections_for_multi_file`. A change lands in **both**, plus `SECTION_DIRECTORIES`, `schema_loader.rb` and `schema_versions.rb` (hashing and stored content read the same directories), plus a round-trip spec.
- Output mode comes from the path: no extension or a trailing `/` = multi-file; `.sql` / `.rb` = single file.
- Only PostgreSQL schema `public` is dumped (`PostgresqlAdapter::DUMPED_SCHEMA`).
- Adding an object type: skill `add-schema-object`.

## Conventions

- Match nearby code. Rubocop is the style authority (`.rubocop.yml`): single quotes, `# frozen_string_literal: true`.
- Adapter and generator rules (batched queries, `supports_*?` parity, quoting): `lib/CLAUDE.md`.
- Test first: generator specs assert the whole SQL statement, not a substring.
- User-visible change: `CHANGELOG.md` under `## [Unreleased]`; options, tasks or output changed: `README.md`, `docs/`, `llms.txt`, and `site/src/pages/` when a page exists.
- Plans: `docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>/` (`/planx`, skill `plan-slices`). One-file fix: no plan.
- Before a PR that touches `lib/` or `app/`: agent `dump-reviewer`. Verification tiers: skill `verify-change`.

## Pull requests

- **`CI OK` is the required check**: the aggregate job of `ci.yml`; every job must pass, skipped or cancelled counts as failed. Live rules: `gh api repos/sebyx07/better_structure_sql/rulesets`. Never restate the list.
- **A PR body claims only what the diff does.** Evidence you could not get is stated as missing. Report what you verified, not what you assume.
- One concern per PR. Keep it a draft (or `WIP` in the title) until ready: a ready, reviewed, green PR is merged by the bot.
- Fill `.github/PULL_REQUEST_TEMPLATE.md`. `bin/check` green on the tree the PR actually contains.

## Release lane

`BetterStructureSql::VERSION` is the single source of truth. Merging a PR that changes it **is** the release: `.github/workflows/release.yml` runs the full CI, publishes through RubyGems trusted publishing (OIDC, no API key), then creates tag `v<version>` and the GitHub Release from the `CHANGELOG.md` section. A merge without a version bump publishes nothing. Steps: `RELEASE.md`; prepare with `/release`.

## AI-maintained

This repository is run by the developerz.ai maintainer agent; policy in `.dz/` (`.dz/README.md`, `.dz/maintainer/maintainer.yml`, `.dz/maintainer/reviewer.md`, `.dz/schedules/`). It triages issues, reviews every PR and **merges on green**, so soak and review happen before the push, not after. Outside changes to `.github/`, `bin/`, the gemspec or `VERSION` stay with the owner; breaking changes ask the owner first.
