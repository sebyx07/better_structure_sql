# BetterStructureSql

[![CI](https://github.com/sebyx07/better_structure_sql/actions/workflows/ci.yml/badge.svg)](https://github.com/sebyx07/better_structure_sql/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/better_structure_sql)](https://rubygems.org/gems/better_structure_sql)
[![Gem Downloads](https://img.shields.io/gem/dt/better_structure_sql)](https://rubygems.org/gems/better_structure_sql)
[![License](https://img.shields.io/github/license/sebyx07/better_structure_sql)](LICENSE)
[![Ruby](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Frubygems.org%2Fapi%2Fv1%2Fversions%2Fbetter_structure_sql.json&query=%24%5B0%5D.ruby_version&label=ruby&color=CC342D)](better_structure_sql.gemspec)
[![Maintained by developerz.ai](https://img.shields.io/badge/maintained%20by-developerz.ai-6f42c1)](https://developerz.ai)
[![Docs](https://img.shields.io/badge/docs-sebyx07.github.io-0a7ea4)](https://sebyx07.github.io/better_structure_sql/)

Clean, deterministic `structure.sql` for Rails, written in pure Ruby. No `pg_dump`, `mysqldump` or `sqlite3` binary: the gem reads the catalog over the ActiveRecord connection and writes the same SQL on every machine. PostgreSQL is the primary target; MySQL (`mysql2` and `trilogy` drivers, MariaDB servers) and SQLite are supported and round-trip tested in CI.

```diff
- --
- -- PostgreSQL database dump
- --
- -- Dumped from database version 16.3
- -- Dumped by pg_dump version 16.4
-
- SET statement_timeout = 0;
- SET lock_timeout = 0;
- SET idle_in_transaction_session_timeout = 0;
- SELECT pg_catalog.set_config('search_path', '', false);
- SET check_function_bodies = false;
- SET xmloption = content;
- SET client_min_messages = warning;
- SET row_security = off;
-
- --
- -- Name: categories; Type: TABLE; Schema: public; Owner: -
- --
-
- CREATE TABLE public.categories (
-     id bigint NOT NULL,
-     name character varying NOT NULL,
-     ...
+ SET client_encoding = 'UTF8';
+ SET standard_conforming_strings = on;
+
+ -- Extensions
+ CREATE EXTENSION IF NOT EXISTS "pgcrypto";
+
+ SET search_path TO "$user", public;
+
+ -- Tables
+ CREATE TABLE IF NOT EXISTS "categories" (
+   "id" bigint NOT NULL DEFAULT nextval('categories_id_seq'::regclass),
+   "name" varchar NOT NULL,
+   "parent_id" integer,
+   PRIMARY KEY ("id")
+ );
+
+ -- Indexes
+ CREATE UNIQUE INDEX index_categories_on_slug ON public.categories USING btree (slug);
+
+ -- Foreign Keys
+ ALTER TABLE "categories" ADD CONSTRAINT "fk_rails_82f48f7407" FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE;
```

## Why

| Problem with the stock dump | What this gem does |
|---|---|
| Tool and server versions leak into the file, so every upgrade is a diff | No version comments, a fixed header, sorted objects |
| Needs the database client binary on every developer machine and in CI | Pure Ruby over the ActiveRecord connection |
| One file with tens of thousands of lines | Optional [multi-file output](#multi-file-output): numbered directories, ~500-line files |
| No record of what the schema looked like at a deploy | Optional [schema versions](#schema-versions-and-web-ui) stored in the database, browsable in a mounted engine |

## Quick start

```ruby
# Gemfile
gem 'better_structure_sql'
```

```bash
bundle install
rails generate better_structure_sql:install   # initializer + schema versions migration
rails db:migrate
rails db:schema:dump_better                    # writes db/structure.sql
```

The database adapter is detected from `ActiveRecord::Base.connection.adapter_name`. The gem depends on `pg`; add `mysql2` (or `trilogy`) or `sqlite3` to your own Gemfile to use those adapters.

`rails generate better_structure_sql:install --skip-migration` skips the schema versions table. To make `rails db:schema:dump` and `rails db:schema:load` use this gem, set `replace_default_dump` and `replace_default_load` in the initializer (see [Configuration](#configuration)). On MySQL and MariaDB a dump loads only through this gem (`replace_default_load` or `db:schema:load_better`): Rails' own load pipes the file through the `mysql` client, which needs `DELIMITER` directives the dump does not contain.

## Feature matrix

What the code dumps today. A dash means the adapter returns nothing for that object type. Every column is round-trip tested in CI (dump, load into an empty database, dump again, compare); the servers and drivers are the `integration-*` jobs in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

| Object | PostgreSQL | MySQL, MariaDB | SQLite |
|---|---|---|---|
| Tables, columns, defaults, primary keys | yes, plus `UNLOGGED`, storage parameters (`WITH (fillfactor=70)`) and inheritance (`INHERITS`, parents first) | yes: server column types verbatim (`int unsigned`, `datetime(6)`, `tinyint(1)`), `AUTO_INCREMENT`, `ON UPDATE`, `ENGINE` / `COLLATE` table options | the original `CREATE TABLE` statement, verbatim (`AUTOINCREMENT`, `WITHOUT ROWID`, `STRICT`, collations, composite primary keys) |
| Identity and generated columns | yes | generated columns | generated columns |
| Check and unique constraints | yes, plus exclusion constraints and `NOT VALID` | checks (where the server has them), `NOT ENFORCED` kept; unique as indexes | as written in the table: named and unnamed checks, table-level `UNIQUE` |
| Partitioned tables | `PARTITION BY` and `PARTITION OF ... FOR VALUES` | - | - |
| Indexes | full definition (method, partial, expression, unique) | full definition (unique, `FULLTEXT`, `SPATIAL`, prefix lengths, `DESC`, functional key parts, `INVISIBLE`) | original `CREATE INDEX` statement, partial and expression included |
| Foreign keys | `ALTER TABLE ... ADD CONSTRAINT`: composite, `MATCH FULL`, `DEFERRABLE`, `NOT VALID` | `ALTER TABLE ... ADD CONSTRAINT`, composite included | inline in `CREATE TABLE`, composite included |
| Views | yes, ordered by dependency | yes, from `SHOW CREATE VIEW` (no database name), ordered by dependency | original `CREATE VIEW` statement |
| Materialized views | yes, with their indexes | - | - |
| Functions | functions and procedures | stored procedures and functions | - |
| Triggers | yes | yes, firing order kept | yes |
| Extensions | yes | - | in their place, the PRAGMAs `application_id`, `auto_vacuum`, `user_version` when non-zero |
| Enum, composite and range types | `CREATE TYPE` | inline `enum(...)` / `set(...)` column types | - |
| Domains | `CREATE DOMAIN` with default, `NOT NULL` and checks | - | - |
| Sequences | `CREATE SEQUENCE`, `OWNED BY` for serial columns | - | - |
| Comments | tables, columns, indexes, views, functions, procedures | tables (column comments are written as SQL comments) | - |
| `schema_migrations` rows | yes | yes | yes |

Not supported:

- PostgreSQL aggregates, rules, row-level security policies.
- PostgreSQL schemas other than `public`: every object is read from `public` only. `config.schemas` is validated but not used.
- Comments on types, sequences, constraints and triggers.
- Dependency ordering across sections: the section order is fixed (extensions, types, functions, sequences, tables, indexes, foreign keys, views, triggers, comments, migrations). Within it, PostgreSQL types, domains, functions, views and materialized views and MySQL views are dependency-ordered.

More detail per adapter: [docs/features/multi-database.md](docs/features/multi-database.md).

## Configuration

`config/initializers/better_structure_sql.rb`. Every option, with the default from [`lib/better_structure_sql/configuration.rb`](lib/better_structure_sql/configuration.rb):

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/structure.sql'  # a path without a file extension means multi-file mode

  config.replace_default_dump = false      # true: rails db:schema:dump uses this gem
  config.replace_default_load = false      # true: rails db:schema:load uses this gem

  config.include_extensions = true
  config.include_custom_types = true
  config.include_domains = true
  config.include_sequences = true
  config.include_functions = true
  config.include_views = true
  config.include_materialized_views = true
  config.include_triggers = true
  config.include_comments = true

  config.search_path = '"$user", public'   # PostgreSQL: written as SET search_path TO ...
  config.sort_tables = true                # alphabetical table order
  config.indent_size = 2
  config.add_section_spacing = true

  config.max_lines_per_file = 500          # multi-file: soft limit per file
  config.overflow_threshold = 1.1          # multi-file: a file may grow to limit * threshold
  config.generate_manifest = true          # multi-file: write _manifest.json

  config.enable_schema_versions = false    # needed by db:schema:store / versions / cleanup
  config.schema_versions_limit = 10        # versions kept; 0 keeps all

  config.adapter = :auto                   # :auto, :postgresql, :mysql, :sqlite
end
```

The initializer written by `better_structure_sql:install` differs from these defaults in three places: it sets `enable_schema_versions = true`, `sort_tables = false` and `search_path = 'public'`.

`replace_default_dump` also switches Rails to `schema_format = :sql`. Both `replace_default_*` options are ignored when `output_path` ends in `.rb`.

Full reference, validation rules and options that exist but have no effect yet: [docs/configuration.md](docs/configuration.md).

## Multi-file output

Point `output_path` at a directory (any path without a file extension) and the dump is split by object type. The numeric prefix is the load order.

```ruby
config.output_path = 'db/schema'
```

```
db/schema/
├── _header.sql
├── _manifest.json
├── 01_extensions/000001.sql
├── 02_types/000001.sql          # enums, composite types, domains
├── 03_functions/000001.sql
├── 04_sequences/000001.sql
├── 05_tables/000001.sql
├── 05_tables/000002.sql
├── 06_indexes/000001.sql
├── 07_foreign_keys/000001.sql
├── 08_views/000001.sql          # views and materialized views
├── 09_triggers/000001.sql
├── 10_comments/000001.sql
└── 20_migrations/000001.sql
```

A directory appears only when it has content. Files are filled up to `max_lines_per_file`; one object is never split across files. `rails db:schema:load_better` loads either a file or a directory.

Details: [docs/features/multi-file-output.md](docs/features/multi-file-output.md).

## Schema versions and web UI

Store each distinct schema in the database, so a developer can read the production schema without database access.

```ruby
config.enable_schema_versions = true
config.schema_versions_limit = 10
```

```bash
rails db:schema:dump_better
rails db:schema:store       # stores a version, or skips when the content hash matches the latest one
rails db:schema:versions    # lists stored versions
rails db:schema:cleanup     # applies schema_versions_limit
CONFIRM=1 rails db:schema:restore[5]  # replaces the database schema with a stored version
```

`db:schema:store` reads the file or directory at `output_path`; it does not dump and does not modify it. In multi-file mode it also stores a ZIP of the directory.

`db:schema:restore` **purges the database** (every table and all data, the stored versions included), then loads the version. It needs `CONFIRM=1` and refuses protected environments such as production, like `db:schema:load`.

Mount the engine to browse, view and download versions:

```ruby
# config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end

# config/initializers/better_structure_sql.rb
BetterStructureSql::Engine.authentication_handled_by_routes!
```

The UI shows your whole schema, so it fails closed: outside development and test every request gets `403 Forbidden` until you declare how access is controlled. Either state that the routes do it (above) or register a check:

```ruby
BetterStructureSql::Engine.authenticate_with do |controller|
  controller.request.env['warden']&.user&.admin?
end
```

Details: [docs/schema_versions.md](docs/schema_versions.md), [docs/features/web-ui.md](docs/features/web-ui.md).

## Rake tasks

| Task | Does |
|---|---|
| `db:schema:dump_better` | Dump to `output_path` |
| `db:schema:load_better` | Load the file or directory at `output_path` (on MySQL, the way to load a dump unless `replace_default_load` is set) |
| `db:schema:store` | Store the dumped schema as a version (skips unchanged content) |
| `db:schema:versions` | List stored versions |
| `db:schema:cleanup` | Delete versions beyond `schema_versions_limit` |
| `db:schema:restore[ID]` | Replace the database schema with a stored version: purges the database first, needs `CONFIRM=1` (`VERSION_ID=5` also works) |
| `db:schema:dump`, `db:schema:load` | Use this gem when `replace_default_dump` / `replace_default_load` are set |

## Documentation

| Topic | Where |
|---|---|
| Docs site with tutorials | <https://sebyx07.github.io/better_structure_sql/> |
| Install | [docs/installation.md](docs/installation.md) |
| Configuration reference | [docs/configuration.md](docs/configuration.md) |
| Tasks and Ruby API | [docs/usage.md](docs/usage.md) |
| Schema versions | [docs/schema_versions.md](docs/schema_versions.md) |
| Multi-file output | [docs/features/multi-file-output.md](docs/features/multi-file-output.md) |
| Adapters | [docs/features/multi-database.md](docs/features/multi-database.md) |
| Web UI | [docs/features/web-ui.md](docs/features/web-ui.md) |
| Moving from `schema.rb` | [docs/migration-guides/from-schema-rb-to-structure-sql.md](docs/migration-guides/from-schema-rb-to-structure-sql.md) |
| Internals | [docs/architecture.md](docs/architecture.md) |
| One-file reference for coding agents | [llms.txt](llms.txt) |
| Changes | [CHANGELOG.md](CHANGELOG.md) |

## AI-maintained

**This project is maintained by [developerz.ai](https://developerz.ai).** Its maintainer agent triages issues, reviews every pull request, merges a pull request once its author marks it ready and CI is green, checks project health daily, and runs a monthly improvement pass. The policy it follows is committed in [`.dz/maintainer/maintainer.yml`](.dz/maintainer/maintainer.yml). Breaking changes and major releases stay with the owner.

- **Using the gem in your app?** Point your agent at [`llms.txt`](llms.txt). Paste this into your app's `CLAUDE.md` / `AGENTS.md`:
  ```markdown
  ## Schema dumps
  `db/structure.sql` (or `db/schema/`) is generated by the better_structure_sql gem; never edit it by hand.
  Before changing its configuration read https://github.com/sebyx07/better_structure_sql/blob/main/llms.txt
  ```
- **Working on this repo?** [`CLAUDE.md`](CLAUDE.md) holds the commands, the code map and the rules; [CONTRIBUTING.md](CONTRIBUTING.md) covers pull requests.

## Development

```bash
bin/setup   # install dependencies and prepare the test database
bin/check   # the gate CI runs: tests and linters
bin/dev     # start the integration app
```

Tests need a reachable PostgreSQL. See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/testing.md](docs/testing.md).

Releases are cut by merging a version bump: see [RELEASE.md](RELEASE.md).

## Security

Report vulnerabilities privately: [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE).

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=sebyx07/better_structure_sql&type=Date)](https://star-history.com/#sebyx07/better_structure_sql&Date)
