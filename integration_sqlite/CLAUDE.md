# sebyx07/better_structure_sql — integration_sqlite

> Workspace brain — established by the developerz.ai maintainer agent for the maintainers of this repository from this workspace, then owned by
> its maintainers. Correct it in place; setup never overwrites a brain that exists.

Full Rails app exercising the gem on SQLite. CI runs the round-trip test.

The gate is the repo root’s: `bin/check` (see the root `CLAUDE.md`).

## Structure

Same layout. **config/database.yml** — SQLite (file-based). **db/structure/** — multi-file dump; SQLite outputs exact CREATE TABLE statements verbatim.

## Conventions

SQLite only. No sequences, functions, custom types. Foreign keys inline. The dump replays verbatim `sqlite_master.sql` entries. CI: `integration-sqlite` job. Same `bss:round_trip` task.
