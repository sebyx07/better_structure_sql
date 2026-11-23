# Configuration

Source of truth: [`lib/better_structure_sql/configuration.rb`](../lib/better_structure_sql/configuration.rb). Set options in `config/initializers/better_structure_sql.rb`:

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/structure.sql'
end
```

`Dumper#dump` calls `config.validate!` and raises `BetterStructureSql::ConfigurationError` on an invalid value.

## Options

### Output

| Option | Default | Effect |
|---|---|---|
| `output_path` | `'db/structure.sql'` | Where the dump is written, relative to `Rails.root`. A path with no file extension (or ending in `/`) selects [multi-file mode](features/multi-file-output.md). Must not be blank. Accepts a `Pathname`. |
| `replace_default_dump` | `false` | `rails db:schema:dump` (and the dump after `db:migrate`) uses this gem for the SQL format. Also sets `config.active_record.schema_format = :sql`. |
| `replace_default_load` | `false` | `rails db:schema:load` uses `BetterStructureSql::SchemaLoader`, which loads a file or a directory. Required on MySQL and MariaDB to load a dump with `rails db:schema:load`: Rails' own load goes through the `mysql` client, which cannot read it. |
| `adapter` | `:auto` | `:auto`, `:postgresql`, `:mysql` or `:sqlite`. `:auto` detects from the connection. See [Options with no or partial effect](#options-with-no-or-partial-effect). |

Both `replace_default_*` options are ignored when `output_path` ends in `.rb`.

Multiple databases: `output_path` applies to the primary database only. Other databases keep the Rails path (`db/<name>_structure.sql`) and are dumped and loaded by this gem at that path. A `SCHEMA=` environment variable overrides the path, as in Rails.

### What to include

All default to `true` except `include_rules`. An option for an object type the database lacks is harmless: the adapter returns an empty list.

| Option | Dumps | Databases |
|---|---|---|
| `include_extensions` | `CREATE EXTENSION`; on SQLite, PRAGMA settings | PostgreSQL, SQLite |
| `include_custom_types` | `CREATE TYPE` for enum, composite and range types | PostgreSQL |
| `include_domains` | `CREATE DOMAIN` | PostgreSQL |
| `include_sequences` | `CREATE SEQUENCE` | PostgreSQL |
| `include_functions` | Functions and procedures | PostgreSQL, MySQL |
| `include_views` | `CREATE OR REPLACE VIEW`; on SQLite the original `CREATE VIEW` statement | all |
| `include_materialized_views` | `CREATE MATERIALIZED VIEW` | PostgreSQL |
| `include_triggers` | `CREATE TRIGGER` | all |
| `include_comments` | `COMMENT ON` for tables, columns, indexes, views, functions; table comments on MySQL | PostgreSQL, MySQL |

Tables, indexes, foreign keys and the `schema_migrations` rows are always dumped.

### Formatting

| Option | Default | Effect |
|---|---|---|
| `search_path` | `'"$user", public'` | PostgreSQL only: written as `SET search_path TO <value>;`. Must not be blank. |
| `sort_tables` | `true` | Sort tables by name. `false` keeps the order the adapter returns, which is also by name on PostgreSQL. |
| `indent_size` | `2` | Spaces per indent level in generated statements. Positive integer. |
| `add_section_spacing` | `true` | Blank line between sections in single-file output. |

### Multi-file

Used only when `output_path` is a directory.

| Option | Default | Effect |
|---|---|---|
| `max_lines_per_file` | `500` | Soft line limit per file. Positive integer. Also sets how many `schema_migrations` versions go in one file. |
| `overflow_threshold` | `1.1` | A file may reach `max_lines_per_file * overflow_threshold` before a new one starts. Must be `>= 1.0`. |
| `generate_manifest` | `true` | Write `_manifest.json` with file and line counts. `false` also removes a manifest left by an earlier dump. |

### Schema versions

| Option | Default | Effect |
|---|---|---|
| `enable_schema_versions` | `false` | Required by `db:schema:store`, `db:schema:versions` and `db:schema:cleanup`. |
| `schema_versions_limit` | `10` | Versions kept after a store. `0` keeps all. Non-negative integer. |

See [schema_versions.md](schema_versions.md).

## Generated initializer vs defaults

`rails generate better_structure_sql:install` writes an initializer that differs from the defaults above:

| Option | Default | Generated initializer |
|---|---|---|
| `enable_schema_versions` | `false` | `true` |
| `sort_tables` | `true` | `false` |
| `search_path` | `'"$user", public'` | `'public'` |

## Options with no or partial effect

These exist on `Configuration` and are validated, but the dump does not change with them yet. Do not rely on them.

| Option | State |
|---|---|
| `schemas` | Default `['public']`. Must be a non-empty array. Not read by introspection: PostgreSQL objects are read from `public` only. |
| `include_rules` | Default `false`. No rule introspection or generator exists. |
| `adapter` | Read by introspection and version detection, but `Dumper` picks headers and quoting from the auto-detected adapter. Leave it at `:auto`. |
| `postgresql` | Reader for an empty `PostgresqlConfig` object, reserved for adapter-specific settings. |

## Web UI access

The engine is configured on `BetterStructureSql::Engine`, not on the configuration object: see [features/web-ui.md](features/web-ui.md).

## Examples

Large schema, Rails tasks replaced:

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'
  config.replace_default_dump = true
  config.replace_default_load = true
end
```

Tables, indexes and foreign keys only:

```ruby
BetterStructureSql.configure do |config|
  config.include_extensions = false
  config.include_custom_types = false
  config.include_domains = false
  config.include_sequences = false
  config.include_functions = false
  config.include_views = false
  config.include_materialized_views = false
  config.include_triggers = false
  config.include_comments = false
end
```

Schema versions in production only:

```ruby
BetterStructureSql.configure do |config|
  config.enable_schema_versions = Rails.env.production?
  config.schema_versions_limit = 20
end
```
