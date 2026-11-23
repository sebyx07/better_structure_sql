# Data model

The gem owns one table and one on-disk layout. Everything else it handles is the host app's
schema, read as plain hashes and never stored.

## The schema versions table

`better_structure_sql_schema_versions`, created by the migration generator
(`lib/generators/better_structure_sql/templates/migration.rb.erb`), model
`lib/better_structure_sql/schema_version.rb`. One row is one stored dump:

| Column | Holds |
|---|---|
| `content` | The dump as text (for a multi-file dump, the files combined) |
| `content_hash` | MD5 hex digest of the content, 32 characters; a store whose hash equals the latest row's is skipped |
| `zip_archive` | The directory as a ZIP, multi-file dumps only |
| `pg_version` | The database version the dump came from (the UI labels it "Database") |
| `format_type` | `sql` or `rb` (check constraint) |
| `output_mode` | `single_file` or `multi_file` (check constraint) |
| `content_size`, `line_count`, `file_count` | Sizes, set before save |
| `created_at` | When it was stored; indexed descending |

Indexes: `created_at`, `content_hash`, `output_mode`. Retention deletes the oldest rows beyond
`schema_versions_limit`, only after a real store (`lib/better_structure_sql/schema_versions.rb`).

## The dump on disk

- **Single file:** one SQL file, sections in a fixed order.
- **Multi-file:** a header file, then numbered section directories (the prefix is the load order)
  holding numbered SQL files, and a manifest with totals. The order is a contract shared by the
  dumper, `FileWriter::SECTION_DIRECTORIES`, the loader and the version hashing: the table in
  `CLAUDE.md` § Dump order is the reference, and `integration/db/schema/` is a committed example.

## In memory

Adapters return arrays of plain hashes with the same keys on every database; generators turn one
hash into one SQL statement (`lib/CLAUDE.md`).
