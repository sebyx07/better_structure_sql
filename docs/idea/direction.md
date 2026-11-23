# Direction

> **Draft for the owner to correct.** Written on 2026-11-23 from `README.md`, `CHANGELOG.md`
> (`## [Unreleased]` and 0.1.0 to 0.2.2), the two issues closed so far (#1, #2) and the pull
> requests merged so far (#3, #5); nothing here was stated by the owner. Every line is a reading
> of what the project already does, not a new goal. Edit it in place, then remove this note. Until
> then, agents treat it as maintenance guidance only, and `scout.survey` stays at its default
> (`broken_only`) in `.dz/maintainer/maintainer.yml`.

## What the product is for

A clean, deterministic structure.sql for a Rails app, written in pure Ruby: the gem reads the
database catalog over the ActiveRecord connection and writes the same SQL on every machine, with no
`pg_dump`, `mysqldump` or `sqlite3` binary. Around that dump it offers a directory of small
numbered SQL files for very large schemas, schema versions stored in the database, and a mountable
web UI to browse them. Readers: Rails teams who keep their schema as SQL in git, developers who
need the current schema without database access, and AI coding tools that read `llms.txt` and the
multi-file layout.

## What "better" means here

Ranked as the shipped work so far ranks it:

1. **A dump loads back, and is the same every time.** Dump, load into an empty database, dump
   again: byte-identical (`CLAUDE.md` § Invariants 2 and 3). Both issues users have filed were
   dumps that did not load (#1 extensions, #2 view dependency order), and the largest group under
   `## [Unreleased]` § Fixed is creation order.
2. **Nothing the database has is silently lost.** Introspection errors raise instead of producing
   an empty section (`## [Unreleased]` § Changed); a missing dump or an unsafe archive raises too.
3. **Complete for what real schemas use.** Each release widens the object types covered: comments
   (0.2.0), then partitions, identity and generated columns, range types, inheritance, MySQL and
   SQLite table and index options (`## [Unreleased]` § Added).
4. **PostgreSQL first, MySQL and SQLite real.** PostgreSQL is the primary target; MySQL (two
   drivers, MariaDB) and SQLite are round-trip tested in CI (`README.md`, the `bss:round_trip`
   entry under `## [Unreleased]` § Added).
5. **Safe by default.** The web UI fails closed outside development and test, a restore needs
   `CONFIRM=1`, ZIP extraction is bounded (`## [Unreleased]` § Upgrading and § Changed).
6. **Usable at very large sizes.** Multi-file output (0.1.0), dependency sorting made linear
   (`## [Unreleased]` § Fixed), the web UI's memory fixes (0.2.2).
7. **A schema history without noise.** Stored versions are deduplicated by content hash and
   pruned by a retention limit (0.2.0).
8. **True docs.** The documentation was rewritten against the code and `llms.txt` added
   (`## [Unreleased]`).
9. **Releases need nobody.** Publishing moved to RubyGems trusted publishing in CI (#3).

## Out of bounds

The policy's `triage.non_goals` in `.dz/maintainer/maintainer.yml` is the list (no external
binary, no non-deterministic or version-dependent output, no table data, no unquoted SQL, no
compatibility shims, among others). It is linked here, not copied.

## Open questions for the owner

- Is a 1.0 release (freezing the dump format and the public API) a goal, and when?
- Should MySQL and SQLite reach PostgreSQL's coverage, or stay a supported subset?
- PostgreSQL schemas other than `public` are not dumped today: planned, or out of bounds?
- Are schema versions and the web UI a place to grow, or to keep as they are?
