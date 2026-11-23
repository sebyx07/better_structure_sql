# Reviewer instructions — sebyx07/better_structure_sql

> Read by the developerz.ai reviewer at EVERY review of this repository, at the reviewed
> commit, as this repo's own layer of the reviewer's prompt. It refines the platform rules
> (a finding is cited or withheld; the bot always discloses) and never overrides them.
> `CLAUDE.md` is the source of truth; this file is its review-time distillation. Keep it under
> 12,000 characters — past that it is cut.

## Stack

`better_structure_sql` is a RubyGems gem that dumps a Rails app's database structure to clean,
deterministic SQL without `pg_dump` / `mysqldump` / the `sqlite3` CLI. Pieces:

- `lib/better_structure_sql/adapters/` — one adapter per database (PostgreSQL, MySQL, SQLite)
  behind `BaseAdapter` and `Registry`; introspection SQL over `pg_catalog`,
  `information_schema`, `sqlite_master` / `PRAGMA`, plus `supports_*?` capability flags.
- `lib/better_structure_sql/introspection/` — thin per-object fetchers delegating to the adapter.
- `lib/better_structure_sql/generators/` — one generator per object type, `generate(object)`
  returns SQL; inherits `Generators::Base`.
- `dumper.rb` (orchestration), `file_writer.rb` + `manifest_generator.rb` (multi-file output in
  numbered directories), `schema_loader.rb` (loads both modes back), `schema_versions.rb` /
  `schema_version.rb` / `zip_generator.rb` (stored versions, MD5 dedup, ZIP archives).
- `app/` + `engine.rb` — a mountable Rails engine browsing stored versions; `railtie.rb` and
  rake tasks.
- Specs: RSpec under `spec/` against a real PostgreSQL (`DATABASE_URL`); adapter specs for MySQL
  and SQLite; `integration*/` are sample apps (excluded from RuboCop).

## What to reject

**SQL injection in introspection**
- A table, schema, type or view name, or any value, interpolated into a query without
  `connection.quote` / `quote_table_name` / `quote_column_name`. Names come from the database,
  but a hostile name (`a'); DROP …`) is a real input: anyone who can create a table can name it.
- A new `$1` placeholder replaced by `gsub` with anything but `connection.quote(...)`.
- Executing SQL taken from config, a stored version, a request param or a file other than the
  schema being loaded by `SchemaLoader` on the developer's own command.

**Determinism (the product's core promise)**
- A new introspection query with no `ORDER BY` (or no Ruby `sort_by` on a stable key) for its
  result list, or a sort on a non-unique key that leaves ties to the server.
- Iterating a Hash built from query rows in insertion order where row order is not fixed.
- Timestamps, hostnames, server-version strings, OIDs, or other run-dependent values in the dump
  body. The header may name the format; it must not vary between runs of the same schema.
- Chunking in `FileWriter` that can split the same schema differently across runs.

**Round-trip loadability**
- Generated SQL that would not load back into the same adapter: unquoted reserved words or mixed
  case identifiers, a missing statement terminator, a default or check expression rewritten.
- A new object type or generator change with no spec that dumps, loads the output into an empty
  database (or asserts the exact SQL) and compares.

**Section ordering**
- The load order is a contract across five places: `Dumper#dump_single_file` (the `*_section`
  methods), `Dumper#generate_sections_for_multi_file`, `FileWriter::SECTION_DIRECTORIES` (the
  numbered directory prefixes), `SchemaLoader#sql_files_in_load_order` and the readers in
  `schema_versions.rb` that hash and store a multi-file dump. Order: extensions, types/domains,
  functions, sequences, tables, indexes, foreign_keys, views/materialized_views, triggers,
  comments, migrations. A change in one without the others is a finding.
- Inside a section, objects that depend on each other are ordered by `CreationOrder` /
  `DependencyResolver` (views, materialized views, functions that need a relation, types that
  need a function or another type). A change that emits such objects in plain name order, or
  drops an object the resolver could not place, is a finding; so is an order that is not
  deterministic for the same schema.
- Foreign keys emitted inline with tables on PostgreSQL/MySQL (they come after all tables); on
  SQLite they are inline by design.

**Adapter parity**
- A capability added to one adapter without the `supports_*?` flag and the other adapters either
  implementing it or returning an empty result (graceful degradation), with a spec per adapter.
- Adapter-specific SQL leaking into a generator that other adapters also call, without a branch
  on the adapter or capability.
- A `require 'mysql2'` / `require 'sqlite3'` at load time: adapter gems load lazily with a
  helpful `LoadError` message.

**Engine security**
- Stored schema content rendered with `raw`, `html_safe` or `<%==`: it is untrusted text
  (comments, function bodies and defaults come from the database). Any XSS path is HIGH.
- `raw` / `download` served as anything but `text/plain` or an attachment, or with a filename
  built from unsanitized input.
- The engine fails closed: outside `development` and `test` every action answers 403 until the
  host calls `Engine.authenticate_with { |controller| ... }` or
  `Engine.authentication_handled_by_routes!`. Anything that weakens that is HIGH: a controller
  or action that skips or bypasses `authenticate_access!`, another environment treated as
  local, a default that allows access, or a rescue that turns a failed check into a pass.
- Loading full ZIP blobs or `content` for list pages (memory): select only needed columns.

**No data leaks**
- Any query that reads table rows, row counts, sequence current values, role passwords or
  connection settings into the dump or a stored version. Structure only; the one row data written
  is the `schema_migrations` version list.
- Logging connection URLs or credentials.

**ZIP and storage**
- Loosening path-traversal checks or the file-count / size limits in `ZipGenerator`.
- Changing what feeds `content_hash` without a dedup spec; retention cleanup running on a skipped
  (deduplicated) store.

**Public API and packaging**
- A breaking change to configuration keys, rake task names, `BetterStructureSql::Dumper` /
  `SchemaVersions` public methods, engine routes or the multi-file directory layout without a
  CHANGELOG entry and a major (or pre-1.0 minor) bump flagged breaking; it escalates to the owner.
- A new runtime dependency in `better_structure_sql.gemspec`, or shelling out to any binary.
- A release by hand: a `v*` tag, `rake release`, `gem push`. Merging a
  `lib/better_structure_sql/version.rb` bump to `main` is the release; a release PR changes only
  the version, `Gemfile.lock`'s own version line and CHANGELOG.
- A user-visible change with no `## [Unreleased]` CHANGELOG line, or a behaviour change that
  leaves README / `llms.txt` / CLAUDE.md stale.
- Syntax newer than RuboCop's `TargetRubyVersion` (the gemspec floor) in `lib/` or `app/`.
- Backwards-compatibility shims, deprecated aliases, or commented-out code.

## Gates that matter

- The one required check is CI's aggregate `CI OK` job (`.github/workflows/ci.yml`). Every job
  under it must pass; none may `continue-on-error`.
- Locally `bin/check` runs RuboCop and the suite against PostgreSQL; it exits 75 (could not
  grade) when Postgres is unreachable. A change that has not passed it is not proven.
- `canary.yml` (monthly: Ruby head, Rails edge, newest PostgreSQL) is not gating; the `improve`
  checkup owns its failures.

## Never flag

- RuboCop-owned style (`.rubocop.yml`, rubocop-rails/rspec/performance): CI enforces it.
- MD5 for `content_hash`: a dedup checksum, not a password or signature.
- The engine being open in `development` and `test` with nothing configured: by design, see
  `app/CLAUDE.md`.
- `pg` as a hard gemspec dependency while MySQL/SQLite gems are optional: current packaging.
- The fixed order of the sections themselves (the numbered directories): by design; only the
  objects inside a section are dependency-sorted.
- Hardcoded SQL, table names and expected dump text in specs: tests should hardcode expectations.
- Heredoc SQL strings longer than a method-length cop would like inside adapters.
- `integration*/` sample apps not following gem style: they are excluded from RuboCop.
- A red monthly `canary.yml`: not gating.
