# Principles

The product's promises are the invariants in `CLAUDE.md` § Invariants; this page says why they
exist, and does not restate them.

- **The dump is a file people commit.** It is reviewed in pull requests and diffed for years, so
  any byte that changes without the schema changing (an unsorted list, a version comment, a
  timestamp) is noise in every user's history. Determinism is the product, not a nicety.
- **A dump that does not load is worse than no dump.** Users find out when a new machine, CI or a
  restore needs it. So the test is the round trip, on a real database: dump, load into an empty
  database, dump again, compare (`spec/integration/postgresql_round_trip_spec.rb`).
- **Fail loudly.** A dump silently missing a section looks fine until it is loaded. An
  introspection error raises; nothing is rescued into an empty list.
- **No binary on the path.** Pure Ruby over the connection removes the client-binary install from
  every developer machine and CI image, and removes its version from the output.
- **Structure only.** A schema file travels where data must not: git, pull requests, the web UI.
  No rows, sequence values or credentials, with the migration version list the one exception.
- **Quoted SQL, on both sides.** Names come from the database being dumped, so they are untrusted
  input to the introspection queries and reserved words in the generated SQL.
- **Closed until opened.** The web UI shows a whole schema; it answers 403 until the host app
  says who may see it.
- **The owner decides what breaks.** Dump format, public methods, rake tasks and version floors
  change only with the owner's decision and an upgrade note in `CHANGELOG.md`.
