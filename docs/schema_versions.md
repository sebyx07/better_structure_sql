# Schema versions

Snapshots of the dumped schema, stored in the application database. One row per distinct schema: storing an unchanged schema is a no-op.

## Setup

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.enable_schema_versions = true
  config.schema_versions_limit = 10   # 0 keeps every version
end
```

```bash
rails generate better_structure_sql:migration   # skipped if better_structure_sql:install already created it
rails db:migrate
```

## Table

`better_structure_sql_schema_versions`, created by [`migration.rb.erb`](../lib/generators/better_structure_sql/templates/migration.rb.erb):

| Column | Type | Holds |
|---|---|---|
| `content` | text, not null | The schema text. Multi-file: every file concatenated in load order |
| `content_hash` | string(32), not null | MD5 hex digest of `content` |
| `zip_archive` | binary, null | Multi-file only: ZIP of the directory |
| `pg_version` | string, not null | Database server version. The name is historical: it holds the MySQL or SQLite version on those databases |
| `format_type` | string, not null | `sql` or `rb` |
| `output_mode` | string, not null | `single_file` or `multi_file` |
| `content_size` | bigint, not null | Bytes |
| `line_count` | integer, not null | Lines |
| `file_count` | integer, null | Multi-file only: number of `.sql` files |
| `created_at` | timestamp, not null | |

Indexes on `created_at`, `content_hash` and `output_mode`; check constraints on `format_type` and `output_mode`.

## Storing

```bash
rails db:schema:dump_better
rails db:schema:store
```

`db:schema:store` reads what is on disk at `config.output_path`; it does not dump.

1. Read the file, or concatenate the directory (`_header.sql`, then each numbered directory's `.sql` files, sorted). `_manifest.json` is not part of the hash.
2. Compute the MD5 of that content.
3. If it equals the latest version's `content_hash`: print "No schema changes detected" and stop. Nothing is written, nothing is cleaned up.
4. Otherwise insert a row. Multi-file mode also stores a ZIP of the directory.
5. Delete the oldest versions beyond `schema_versions_limit`.

The file or directory on disk is never modified.

Deduplication compares against the latest version only: reverting to an older schema stores a new row.

`Dumper#dump` with `store_version: true` (the default when `enable_schema_versions` is on and no argument is given) dumps and stores in one call. It raises if storing fails, for example when the versions table has not been migrated. The `db:schema:dump_better` task passes `store_version: false`.

## Listing and cleanup

```bash
rails db:schema:versions   # id, format, mode, files, database version, first 8 hash characters, created, size
rails db:schema:cleanup    # delete versions beyond schema_versions_limit
```

Cleanup runs automatically after every store that creates a row.

## Restoring

```bash
CONFIRM=1 rails db:schema:restore[5]
CONFIRM=1 VERSION_ID=5 rails db:schema:restore
```

Restore **replaces** the schema of the current database with the stored version:

1. Read the version, and write it to a temporary directory (extracting the ZIP for multi-file versions).
2. Purge the database: every table and all data are dropped, the `better_structure_sql_schema_versions` table and its stored versions included.
3. Load the version with `SchemaLoader`.
4. Record the environment and the schema checksum (`schema_sha1`) in `ar_internal_metadata`, as Rails' own schema load does.

Safeguards:

- Without `CONFIRM=1` the task aborts with a message naming the database and changes nothing.
- Rails' protected-environment check runs first (`db:check_protected_environments`): a production database is refused unless `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` is set.

There is no rollback: a version that fails to load leaves the database purged. Back up data you need, and download the versions you want to keep (web UI or `SchemaVersion#content`) before restoring. The schema file or directory on disk is not touched; dump afterwards if it should match.

It works for `sql` and `rb` versions on every supported database.

## Ruby API

`BetterStructureSql::SchemaVersions` ([source](../lib/better_structure_sql/schema_versions.rb)):

| Method | Returns |
|---|---|
| `store_current(connection = ActiveRecord::Base.connection, config: BetterStructureSql.configuration)` | `StoreResult`. Raises `SchemaVersionError` when nothing is on disk at `output_path`. Never modifies the file or directory |
| `store(content:, content_hash:, format_type:, pg_version:, output_mode: 'single_file', zip_archive: nil, file_count: nil)` | `SchemaVersion`. No deduplication, no cleanup |
| `latest` | Newest `SchemaVersion` or `nil` |
| `all_versions` | Array, newest first |
| `find(id)` | `SchemaVersion` or `nil` |
| `count` | Integer |
| `by_format(format_type)` | Array for `'sql'` or `'rb'` |
| `calculate_hash(content)` | MD5 hex digest |
| `latest_hash` | Hash of the newest version or `nil` |
| `hash_exists?(hash)` | Boolean |
| `find_by_hash(hash)` | Newest `SchemaVersion` with that hash, or `nil` |
| `cleanup!` | Number of versions deleted |
| `restore(version, db_config: ActiveRecord::Base.connection_db_config)` | Nothing. Purges the database, loads the version, records the environment and `schema_sha1`. No confirmation and no protected-environment check: those belong to the rake task |

Query methods return `nil`, `[]` or `0` when the table does not exist; `store` and `store_current` raise.

`BetterStructureSql::StoreResult`: `stored?`, `skipped?`, `version`, `version_id`, `hash`, `total_count`.

`BetterStructureSql::SchemaVersion` is an ActiveRecord model:

| Member | Returns |
|---|---|
| `SchemaVersion.latest` | Newest record |
| Scopes `latest_first`, `oldest_first`, `recent(n)`, `by_format(type)`, `by_output_mode(mode)` | Relations |
| `#size`, `#formatted_size` | Bytes; `"45.2 KB"` |
| `#multi_file?`, `#zip_archive?` | Boolean |
| `#hash_matches?(hash)` | Boolean |
| `#extract_zip_to_directory(dir)` | `dir`, or `nil` without an archive |

Store a custom snapshot:

```ruby
content = File.read('db/structure.sql')
BetterStructureSql::SchemaVersions.store(
  content: content,
  content_hash: BetterStructureSql::SchemaVersions.calculate_hash(content),
  format_type: 'sql',
  pg_version: BetterStructureSql::PgVersion.detect
)
```

Diff two versions:

```ruby
a, b = BetterStructureSql::SchemaVersions.find(3), BetterStructureSql::SchemaVersions.find(5)
File.write('tmp/a.sql', a.content)
File.write('tmp/b.sql', b.content)
system('diff', '-u', 'tmp/a.sql', 'tmp/b.sql')
```

## schema.rb

With `config.output_path = 'db/schema.rb'` the gem does not dump (Rails writes `schema.rb`), but `db:schema:store` stores that file with `format_type = 'rb'`. See [migration-guides/from-schema-rb-to-structure-sql.md](migration-guides/from-schema-rb-to-structure-sql.md).

## Browsing

Mount the engine to list, view and download versions in a browser: [features/web-ui.md](features/web-ui.md).

## Sizing

- Each version stores the full schema text, and multi-file versions also store a ZIP. Keep `schema_versions_limit` low for large schemas.
- `ZipGenerator.extract_to_directory` raises `ZipError` for an entry that resolves outside the target directory or when the limits are exceeded; it overwrites existing files.
- ZIP limits (file count, uncompressed size) are constants in [`zip_generator.rb`](../lib/better_structure_sql/zip_generator.rb).
