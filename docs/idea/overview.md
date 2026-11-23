# Overview

better_structure_sql is a Ruby gem for Rails apps that keep their database schema as SQL. It
replaces the stock structure dump (which shells out to the database's client binary and leaks tool
and server versions into the file) with one written in pure Ruby: it reads the catalog over the
ActiveRecord connection and writes sorted, version-free SQL, so the same schema gives the same
bytes on every machine.

What it does beyond the single file:

- **Multi-file output:** a directory of numbered section directories with files of about 500
  lines, for schemas too large to read or diff as one file (`docs/features/multi-file-output.md`).
- **Schema versions:** each dump can be stored in a database table, deduplicated by content hash
  and pruned by a retention limit (`docs/schema_versions.md`).
- **Web UI:** a mountable Rails engine to browse and download stored versions; it refuses every
  request outside development and test until the host app declares access control
  (`docs/features/web-ui.md`).

PostgreSQL is the primary target; MySQL (including MariaDB) and SQLite are supported
(`docs/features/multi-database.md`).

It is a public gem on RubyGems, maintained by the developerz.ai agent under the policy in
`.dz/maintainer/maintainer.yml`. Where things live and how a dump is built: `CLAUDE.md`
§ Architecture and `docs/architecture.md`. The docs site is https://sebyx07.github.io/better_structure_sql/
(source in `site/`).
