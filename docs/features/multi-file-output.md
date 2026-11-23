# Multi-file output

Split the dump into one directory per object type, in files of bounded size. Diffs touch only the files that changed, and no file is too large to read.

## Enable

```ruby
BetterStructureSql.configure do |config|
  config.output_path = 'db/schema'     # no file extension = directory mode
  config.max_lines_per_file = 500
  config.overflow_threshold = 1.1
  config.generate_manifest = true
end
```

Mode is decided by the path alone: `File.extname(output_path)` empty (or a trailing `/`) means multi-file.

## Layout

```
db/schema/
├── _header.sql              # session settings, e.g. SET search_path (PostgreSQL), PRAGMA (SQLite)
├── _manifest.json           # file and line counts
├── 01_extensions/
├── 02_types/                # enums, composite types, domains
├── 03_functions/
├── 04_sequences/
├── 05_tables/
├── 06_indexes/
├── 07_foreign_keys/
├── 08_views/                # views, then materialized views
├── 09_triggers/
├── 10_comments/
└── 20_migrations/           # INSERT INTO schema_migrations
```

| Rule | Detail |
|---|---|
| Directory names | Fixed, defined in [`file_writer.rb`](../../lib/better_structure_sql/file_writer.rb). The numeric prefix is the load order. |
| Empty sections | No directory is written. SQLite has no `07_foreign_keys` (keys are inline). |
| File names | `000001.sql`, `000002.sql`, ... per directory. |
| Stale files | A dump removes files and directories left by a previous, larger dump. |

## Chunking

- Objects are appended to a file until it reaches `max_lines_per_file`.
- An object that would cross the limit still goes in the current file if the result stays within `max_lines_per_file * overflow_threshold`; otherwise it starts a new file.
- One object is never split. An object longer than the limit gets a file of its own.
- `schema_migrations` versions are written as one `INSERT` per file, sized from `max_lines_per_file`.
- The blank line between objects counts toward the limit.
- The same schema always produces the same split.

## Manifest

`_manifest.json` (written when `generate_manifest` is true):

```json
{
  "version": "1.0",
  "total_files": 12,
  "total_lines": 2369,
  "max_lines_per_file": 500,
  "directories": {
    "01_extensions": { "files": 1, "lines": 3 },
    "05_tables": { "files": 2, "lines": 979 }
  }
}
```

It is informational. The loader orders files by directory and file name, not by the manifest.

## Loading

```bash
rails db:schema:load_better
```

`SchemaLoader` executes `_header.sql`, then every `.sql` file of every numbered directory in sorted order. With `config.replace_default_load = true`, `rails db:schema:load`, `db:setup` and the test-schema maintenance in `rails_helper` use the same loader.

The gem also patches ActiveRecord so a schema directory works where Rails expects a file, whatever the `replace_default_*` options say: the schema checksum is computed over all `.sql` files, the schema-file check accepts a directory that contains `.sql` files, and Rails' `structure_load` hands a directory to `SchemaLoader` (so `rails db:schema:load` loads one even with `replace_default_load` off). `maintain_test_schema!` delegates to Rails when `replace_default_dump` or `replace_default_load` is on, because Rails then resolves the directory itself; with both off and a directory at `output_path`, it purges the test database and loads the directory through Rails' `load_schema` when the checksum differs (recording the environment and `schema_sha1`), then checks for pending migrations. Source: [`migration_patch.rb`](../../lib/better_structure_sql/migration_patch.rb).

## With schema versions

A multi-file version stores the concatenated text plus a ZIP of the directory. `rails db:schema:store` leaves the directory on disk untouched; see [../schema_versions.md](../schema_versions.md#storing). The web UI offers the ZIP as a download.

## Switching modes

| From | To | Steps |
|---|---|---|
| `db/structure.sql` | `db/schema` | Change `output_path`, dump, `git rm db/structure.sql`, commit the directory |
| `db/schema` | `db/structure.sql` | Change `output_path`, dump, `git rm -r db/schema`, commit the file |
