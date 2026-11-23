# Post-merge fix sweep

Weekly sweep, Thursdays 02:00 UTC, OFFERED and off: the `fix-sweep` entry in
`.dz/maintainer/maintainer.yml` is commented out, and uncommenting it is the opt-in. It runs as a
devops task (`mode: devops`: a shell on a checkout, at most one pull request). It is the
developerz.ai platform's standard fix sweep, adapted to better_structure_sql: the changes merged
into `main` in the last 7 days, read again for the defects their own review let through, and fixed
in one pull request. Read `CLAUDE.md` and `lib/CLAUDE.md` first: their invariants bind every fix.

## 1. Find the touched area

```bash
bin/setup
git log --since='7 days ago' --first-parent --format='%h %s' origin/main
git diff --stat "$(git rev-list -1 --before='7 days ago' origin/main)" origin/main
```

`bin/setup` exiting 75 means the environment is missing (Ruby, gems, Docker, PostgreSQL): nothing
can be proved, so say so and stop. The touched area is the changed files and their direct callers
along the flow adapter -> `Introspection` -> generator -> `Dumper` section -> `FileWriter` /
`SchemaLoader`. Nothing merged, or only dependency bumps with a green `main`: say so and stop.

## 2. Hunt

Read the touched area for, worst first:

- **correctness**: a dump that no longer loads back or differs on a second run (an introspected
  list with no `ORDER BY` or Ruby sort, hash-order iteration, an unquoted identifier or reserved
  word); a section changed in the single-file path and not the multi-file one, or not in
  `FileWriter::SECTION_DIRECTORIES`, `schema_loader.rb` and `schema_versions.rb`; an error path
  swallowed by a blanket `rescue` so a section comes out empty; a name or value interpolated
  unquoted into introspection SQL
- **adapter parity**: a `fetch_*` or `supports_*?` added to one adapter with neither an
  implementation nor an explicit no-op on the other two
- **cost**: a catalog query issued one per table or column in a loop, all stored versions read
  with their content to page or filter in Ruby, a new filter or sort on the versions table that
  no index serves
- **lifetime**: a temporary file or directory, file handle or cache that outlives its owner
- **reuse**: a new copy of a helper the gem already has (quoting, sorting, splitting, hashing);
  name both
- **drift**: a line in `README.md`, `llms.txt`, `docs/`, a `CLAUDE.md` or `site/src/pages/` that
  the merged change made false

Skip fixtures and generated files. Confirm before you claim: a defect is one you can make fail.

## 3. Fix

- One pull request for the whole sweep, one goal: the defects this week's merges brought in.
- For each defect, a spec that fails before the fix and passes after. A generator spec asserts the
  whole statement; a dump defect on PostgreSQL adds the object to
  `spec/fixtures/postgresql_round_trip.sql` so the round-trip spec pins it. Run it red first.
- A user-visible fix carries a `CHANGELOG.md` `## [Unreleased]` line.
- Delete what the fix makes dead.
- `bin/check` (full, on PostgreSQL) must be green before you open the pull request. Exit 75 is a
  missing environment, never a pass.
- A defect you cannot make fail is not fixed here: name it in the report, with no pull request for
  it.
- A fix that changes dump output format, a public method, a rake task or a version floor is
  breaking: report it for the owner.
- Do not edit `.github/`, `.dz/`, the gemspec or `lib/better_structure_sql/version.rb`.

No defect: no pull request. A clean week is a good result; say so and stop.

## Report

The range of merges you read, each defect with its `path:line`, its spec and its fix, and what you
could not cover, with why.
