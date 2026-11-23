---
description: Sweep one area of better_structure_sql for defects — run the detectors below, fix each with a failing spec first, ship one goal-scoped pull request. Use for bug sweep, find bugs, fix everything in, QA pass.
argument-hint: <the area or goal to sweep, e.g. "mysql adapter" or "schema versions">
---

# /bug-sweep — find and fix defects in one area

Sweep `$ARGUMENTS` for defects. A clean area reported clean is a success: never invent a defect to have something to ship, never fix what is not broken. Read `CLAUDE.md` and the nested `CLAUDE.md` of the directory you sweep first; their invariants bind every fix.

## Steps

1. Read the area (the adapter, generator, dumper section, loader or controller, and its specs), then run each detector below over it. Read the code that does the thing, not only a file that mentions it.
2. For each defect: write the failing spec first and watch it fail, then fix the cause. A generator spec asserts the whole statement; a PostgreSQL dump defect adds the object to `spec/fixtures/postgresql_round_trip.sql` so the round-trip spec pins it.
3. A defect class that recurred is fixed as a class: a spec, a RuboCop cop or a guard that makes the next one fail, in the same change.
4. Prove it with `bin/check` (full, on PostgreSQL; `BSS_TEST_DB=<name>` when agents share the checkout). Exit 75 means the environment is missing: run `bin/setup`, never report it as a pass or a failure. Red is not a pull request: fix the cause, never silence the check (skill `verify-change`).
5. Before the pull request, when the diff touches `lib/` or `app/`: agent `dump-reviewer`.
6. Ship one goal-scoped pull request for the area, every defect in it with its spec, and a `CHANGELOG.md` `## [Unreleased]` line for what users see. A defect outside the area is its own pull request, named in the body.
7. The body lists each defect: the schema or input that broke it, the spec that pins it, the fix.

A fix that changes dump output format, a public method, a rake task or a version floor is breaking: report it and stop for the owner.

## What to hunt — run the detector, do not just read

| Class | Detector |
|---|---|
| Dump that does not load back, or differs on a second run | add the object to the round-trip fixture and run `bin/check files spec/integration/postgresql_round_trip_spec.rb`; on MySQL or SQLite, `bin/rails bss:round_trip` in the integration app |
| Unordered introspection | a `fetch_*` query with no `ORDER BY` and no Ruby sort; iteration over a hash whose order comes from the database |
| Unquoted name or value | a string interpolated into introspection SQL outside `connection.quote`; a generated identifier outside `quote_identifier`. Try a table named with a quote, a dot, a comma and a reserved word |
| Swallowed error | `rescue StandardError` or `rescue => e` that returns `[]` or `nil` or only logs; make the query fail and see whether the dump still "succeeds" |
| Section drift | an object type present in the single-file `*_section` path and absent from `generate_sections_for_multi_file`, `FileWriter::SECTION_DIRECTORIES`, the loader or the version hashing, or the reverse |
| Adapter parity | a `fetch_*` or `supports_*?` on one adapter with no implementation and no explicit no-op on the other two |
| Per-table query | a catalog query inside a loop over tables, columns or indexes; batch it and build a lookup hash |
| Unbounded read in the engine | all stored versions loaded with `content` or `zip_archive` to page or filter in Ruby |
| Engine exposure | a controller action without `authenticate_access!`, stored content rendered with `raw` or `html_safe`, a download that is not `text/plain` or an attachment |
| Hostile archive | ZIP extraction reachable without the traversal, file-count or size limits; the spec uses a hostile archive |
| Temporary file left behind | a temp file or directory not removed on the error path |
| A doc, `llms.txt` line or site page the code no longer matches | read the sentence against the option, task or directory name it describes |
| Guard that proves nothing | break the guarded thing; if the spec stays green, the spec is the bug (a substring match on SQL, a mocked database in `spec/integration/`) |
| Missing spec | an object type, option or branch that can be wrong and that no spec would catch |
