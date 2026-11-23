# Hygiene checkup

Weekly checkup, Sundays 20:00 UTC, OFFERED and off: the `hygiene` entry in
`.dz/maintainer/maintainer.yml` is commented out, and uncommenting it is the opt-in. It is the
developerz.ai platform's standard hygiene checkup, adapted to a Ruby gem that introspects
databases: a deep read for the defects tests never show. A read-only scout: you read files only, no
shell, network or database, so a finding whose harm depends on a size or a rate you cannot see (how
many tables a schema has, how long a catalog query takes) is marked `measure first: yes`, never
guessed. Read `CLAUDE.md` and `lib/CLAUDE.md` first: their invariants define what a defect is here.

## What to look for

1. **Resource lifetimes.** In `lib/` and `app/`: a temporary file or directory (ZIP extraction,
   restore, atomic writes in `file_writer.rb`) not removed on every exit path, the error path
   included; a file handle opened without a block; a connection checked out and not returned; the
   per-connection adapter cache in `adapters/registry.rb` or any module-level cache that only
   grows; a whole dump or archive held in memory where the code already streams elsewhere.
2. **Algorithms.** One catalog query per table, column or index inside a loop (N+1: `lib/CLAUDE.md`
   requires one batched query per object type and a lookup hash); a linear search inside a loop
   over all objects of a schema; a regular expression built inside a loop; in the engine and
   `schema_versions.rb`, all stored versions loaded (their `content` and `zip_archive` columns
   included) and then paged or filtered in Ruby, or a query with no limit on the versions table.
3. **Reuse.** A hand-rolled copy of a helper the gem already has: identifier quoting outside
   `Generators::Base#quote_identifier`, value quoting outside `connection.quote`, a second
   topological sort beside `dependency_resolver.rb`, statement splitting outside
   `schema_loader.rb`, hashing outside `schema_versions.rb`. Name both the copy and the original.
4. **Data.** From `lib/generators/better_structure_sql/templates/migration.rb.erb` and the
   queries in `schema_version.rb`, `schema_versions.rb` and `app/controllers/`: an index on the
   versions table that duplicates another or that no query filters, sorts or joins on; a query the
   gem runs on that table that no index serves. The migrations under `integration*/db/migrate/`
   are test fixtures built to exercise the dumper: never file their indexes.
5. **Documentation drift.** In `README.md`, `llms.txt`, `CLAUDE.md` and its nested files, `docs/`,
   `CONTRIBUTING.md`, `RELEASE.md` and `site/src/pages/`: a path that no longer exists, a rake task
   or `bin/` script the repository does not define, a configuration option, default or
   `supports_*?` flag the code no longer has, a section directory name that differs from
   `FileWriter::SECTION_DIRECTORIES`, a version list copied from the CI matrix (docs must point at
   it instead). Quote both the doc line and the code.
6. **Code quality.** A blanket `rescue StandardError` or `rescue => e` that returns `[]` or `nil`
   or only logs (a dump silently missing objects); a file or method far beyond the others' size;
   dead code (a method nothing calls, a configuration option nothing reads, an adapter `fetch_*`
   no section uses); a `supports_*?` flag one adapter has and another lacks.
7. **Infrastructure.** `Dockerfile`, `Dockerfile.mysql`, `docker-compose.yml`,
   `docker-compose.mysql.yml` and `docker-entrypoint.sh` are the development environment, not a
   deployment: a base image whose Ruby is below the gemspec floor or differs from `.ruby-version`,
   an unpinned image, no non-root user, a credential beyond the documented local defaults, a copy
   of the whole context that `.dockerignore` does not trim. Quote the key, never a secret's value.
   Skip CI configuration (workflow files) and secret-shaped paths: a handoff naming one is refused
   whole.

## Rows

One per area above; a handoff reports one failing row.

- `leak`: resource lifetimes
- `algo`: algorithms
- `reuse`: reuse
- `index`: data
- `doc-drift`: documentation drift
- `quality`: code quality
- `infra`: infrastructure

## How to judge

- Confirm before you claim: read the call path. A pattern is a finding only once you have seen
  that it runs where it hurts (per dump, per request, per stored version).
- Rank by blast radius: what breaks users first (a dump that loses objects or does not load back,
  a leak or unbounded read in the engine, a doc naming a task that does not exist), quality last.
- Skip `spec/`, fixtures, the `integration*/` apps' generated schema and `site/` build tooling.
  Skip `.dz/`.
- One handoff per row: every defect in an area goes in it, worst first.
- A finding whose fix changes dump output, a public method or a version floor is breaking: report
  it for the owner, do not file it.

## Every finding

Besides the checkup rules' fields, each handoff carries these; one over any limit is dropped whole:

- **work**: one sentence naming the defect and the fix, at most 300 characters.
- **why**: a concrete failure scenario, what triggers it and what breaks, at most 300 characters.
- **evidence**: at most 10 lines of at most 280 characters each. Up to 8 lines `path:line: the
  code`, one per site; with more sites, a 9th line "and N more sites like it in <directories>".
  The last line starts `measure first:`. Write `measure first: no` with the reason when the code
  alone proves the harm, or `measure first: yes` with what to measure and how when it depends on
  sizes or rates. The coding agent that takes the handoff measures on its own stack first, and
  drops the fix if the number shows no harm.
- **paths**: at most 20 files.
- **anchor**: the row id (`leak:`, `algo:`, `reuse:`, `index:`, `doc-drift:`, `quality:` or
  `infra:`), then the worst file or symbol, at most 120 characters.
- **metric**: the number the fix moves, at most 200 characters.

## Report

For each of the seven areas: what you read and whether it was clean. Name any area you could not
cover, and why.
