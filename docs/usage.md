# Usage

## Rake tasks

| Task | Does | Needs |
|---|---|---|
| `rails db:schema:dump_better` | Dump the schema to `config.output_path`; print file count and size | - |
| `rails db:schema:load_better` | Execute the file or directory at `config.output_path` against the database, then record the environment and schema checksum in `ar_internal_metadata` | Refuses protected environments, like `db:schema:load` |
| `rails db:schema:store` | Store the dumped schema as a version; skip when unchanged | `enable_schema_versions` |
| `rails db:schema:versions` | List stored versions | `enable_schema_versions` |
| `rails db:schema:cleanup` | Delete versions beyond `schema_versions_limit` | `enable_schema_versions` |
| `rails db:schema:restore[ID]` | Replace the database schema with a stored version: purge the database (all data and the stored versions are lost), load the version, record the environment and schema checksum. `VERSION_ID=5` also works | A stored version, `CONFIRM=1`; refuses protected environments |

With `config.replace_default_dump = true`, `rails db:schema:dump` and the dump Rails runs after `db:migrate` use this gem. With `config.replace_default_load = true`, `rails db:schema:load` (and the tasks built on it) load a file or a directory through this gem.

`db:schema:load_better` executes SQL as-is. It does not drop existing objects first: load into an empty database. After loading it records the environment and the schema checksum (`schema_sha1`) in `ar_internal_metadata`, as Rails' own load does, so `db:drop` and `db:purge` work afterwards.

`db:schema:restore` is destructive: it purges the database before loading. See [schema_versions.md](schema_versions.md#restoring).

On MySQL and MariaDB a dump must be loaded through this gem (`replace_default_load = true`, `db:schema:load_better` or `SchemaLoader`). Rails' own `structure.sql` load pipes the file through the `mysql` client, which needs `DELIMITER` directives around routine and trigger bodies; the dump has none. See [Loading a MySQL dump](features/multi-database.md#loading-a-mysql-dump).

## Workflows

Commit a clean dump:

```bash
rails db:migrate
rails db:schema:dump_better   # not needed when replace_default_dump = true
git add db/structure.sql      # or db/schema/
```

Record the schema at deploy time:

```bash
rails db:migrate
rails db:schema:dump_better
rails db:schema:store         # no new row when the schema did not change
```

Create a database from the dump:

```bash
rails db:create
rails db:schema:load_better
```

## Ruby API

### Dump

```ruby
dumper = BetterStructureSql::Dumper.new            # (config = BetterStructureSql.configuration, connection = ActiveRecord::Base.connection)
output = dumper.dump(store_version: false)
```

| Mode | Return value |
|---|---|
| Single file | `String`: the SQL written to `output_path` |
| Multi-file | `Hash`: relative path (`'05_tables/000001.sql'`) => content |

`store_version:` defaults to `config.enable_schema_versions`: pass `false` to dump without storing a version. When it stores, it deduplicates like `db:schema:store`, keeps a multi-file directory on disk, and raises if storing fails, including when the versions table has not been migrated. `dump` validates the configuration first and raises `BetterStructureSql::ConfigurationError` on a bad value.

### Load

```ruby
BetterStructureSql::SchemaLoader.new.load            # config.output_path
BetterStructureSql::SchemaLoader.new.load('db/schema')
```

Files are written atomically (temporary file, then rename), so an interrupted dump does not leave a half-written file.

Raises `BetterStructureSql::SchemaLoader::LoadError` when the path does not exist. A path ending in `.rb` is handed to Rails' Ruby schema loader.

### Schema versions

```ruby
result = BetterStructureSql::SchemaVersions.store_current
result.stored?      # true when a row was created
result.skipped?     # true when the content hash matched the latest version
result.version      # SchemaVersion, when stored
result.version_id   # id of the stored or matching version
result.hash         # MD5 content hash
result.total_count

BetterStructureSql::SchemaVersions.latest          # SchemaVersion or nil
BetterStructureSql::SchemaVersions.all_versions    # newest first
BetterStructureSql::SchemaVersions.find(id)        # nil when missing
BetterStructureSql::SchemaVersions.count
BetterStructureSql::SchemaVersions.cleanup!        # returns the number deleted
```

Full model and method reference: [schema_versions.md](schema_versions.md).

### Errors

All inherit from `BetterStructureSql::Error`, defined in [`lib/better_structure_sql/errors.rb`](../lib/better_structure_sql/errors.rb): `ConfigurationError`, `SchemaVersionError`, `AdapterError`, `IntrospectionError`, `GenerationError`, `FileError`. `SchemaLoader::LoadError` and `ZipGenerator::ZipError` inherit from `StandardError`.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Schema versioning is not enabled.` | Set `config.enable_schema_versions = true`. |
| `Schema versions table does not exist` | `rails generate better_structure_sql:migration && rails db:migrate`. |
| `No schema found at ...` from `db:schema:store` (exit 1) | The task stores what is on disk. Run `rails db:schema:dump_better` first. |
| `Dumper#dump` raises about the versions table | `enable_schema_versions` is on and `dump` was called without `store_version: false`. Migrate the table or pass `false`. |
| `relation already exists` on load | `db:schema:load_better` does not drop objects. Load into an empty database. |
| An object in a non-`public` PostgreSQL schema is missing | Only `public` is dumped. See [features/multi-database.md](features/multi-database.md). |
| An object fails to load because it depends on a later one | Views are dependency-ordered on PostgreSQL; other sections are in name order and the section order is fixed. Report it with the definitions. |
