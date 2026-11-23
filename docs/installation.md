# Installation

## Requirements

| Need | Source of truth |
|---|---|
| Ruby and Rails versions | [`better_structure_sql.gemspec`](../better_structure_sql.gemspec) |
| Versions tested | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) |
| A database gem | `pg` is a dependency of this gem; add `mysql2` or `trilogy`, or `sqlite3`, yourself for those adapters |

No database client binary (`pg_dump`, `mysqldump`, `sqlite3`) is needed.

## Install

```ruby
# Gemfile
gem 'better_structure_sql'
```

```bash
bundle install
rails generate better_structure_sql:install
rails db:migrate
```

The generator creates:

| File | Purpose |
|---|---|
| `config/initializers/better_structure_sql.rb` | Configuration ([reference](configuration.md)) |
| `db/migrate/*_create_better_structure_sql_schema_versions.rb` | Table for [schema versions](schema_versions.md) |

Skip the table with `rails generate better_structure_sql:install --skip-migration`, and set `config.enable_schema_versions = false` in the generated initializer. Add the table later with `rails generate better_structure_sql:migration`.

## First dump

```bash
rails db:schema:dump_better
```

This writes `config.output_path` (`db/structure.sql` unless changed) and prints the size. Commit the result.

## Replace the Rails tasks

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.replace_default_dump = true   # rails db:schema:dump, and the dump after db:migrate
  config.replace_default_load = true   # rails db:schema:load, db:setup, db:test:prepare
end
```

`replace_default_dump` sets `config.active_record.schema_format = :sql` for you. Without these options, use `db:schema:dump_better` and `db:schema:load_better` explicitly.

## Databases

The adapter is chosen from `ActiveRecord::Base.connection.adapter_name`:

| Connection adapter | Adapter used | Extra gem |
|---|---|---|
| `postgresql`, `postgis` | PostgreSQL | none |
| `mysql2`, `trilogy` | MySQL, MariaDB | the driver you use: `mysql2` or `trilogy` |
| `sqlite3` | SQLite | `sqlite3` |

Any other adapter raises `BetterStructureSql::Error`. PostgreSQL is the primary target; MySQL and SQLite are round-trip tested in CI. On MySQL, load dumps through the gem (`replace_default_load = true` or `db:schema:load_better`): Rails' own load cannot read them, see [Loading a MySQL dump](features/multi-database.md#loading-a-mysql-dump). What each adapter dumps: [features/multi-database.md](features/multi-database.md).

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Schema versions table does not exist` | Run `rails generate better_structure_sql:migration` then `rails db:migrate`. |
| `Schema versioning is not enabled.` | Set `config.enable_schema_versions = true`. |
| `rails db:schema:dump` still calls `pg_dump` | Set `config.replace_default_dump = true`; check `output_path` does not end in `.rb`. |
| `MySQL support requires the mysql2 gem` (or `the trilogy gem`) / `SQLite support requires the sqlite3 gem` | Add the named gem to your Gemfile. |
| `Unsupported database adapter` | Only PostgreSQL, MySQL and SQLite connections are supported. |
| Web UI answers `403 Forbidden` in production | Declare access control: [features/web-ui.md](features/web-ui.md). |
