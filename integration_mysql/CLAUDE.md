# sebyx07/better_structure_sql — integration_mysql

> Workspace brain — established by the developerz.ai maintainer agent for the maintainers of this repository from this workspace, then owned by
> its maintainers. Correct it in place; setup never overwrites a brain that exists.

Full Rails app exercising the gem on MySQL/MariaDB. CI runs the round-trip test.

The gate is the repo root’s: `bin/check` (see the root `CLAUDE.md`).

## Structure

Same layout as `integration/`. **config/database.yml** — MySQL. **db/schema/** — multi-file dump. Proves MySQL adapter works end-to-end.

## Conventions

MySQL/MariaDB only. The gem reads views from SHOW CREATE VIEW (no `information_schema` joins). Foreign keys are inline in CREATE TABLE. CI configuration in `.github/workflows/ci.yml`: `integration-mysql` job. Same `bss:round_trip` task as PostgreSQL.
