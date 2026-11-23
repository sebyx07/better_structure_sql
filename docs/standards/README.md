# Standards

How work is done here, and the check that enforces each rule. The rules themselves live in
`CLAUDE.md` (invariants, never, conventions, pull requests) and its nested files (`lib/CLAUDE.md`,
`spec/CLAUDE.md`, `app/CLAUDE.md`, `.github/CLAUDE.md`); this page is the map from rule to guard.

| Rule | Enforced by |
|---|---|
| Repo guards, lint and the full suite pass on PostgreSQL | `bin/check`, and `CI OK` in CI |
| Ruby style: single quotes, frozen string literals, Rails and RSpec cops | RuboCop (`.rubocop.yml`) |
| A dump loads back and re-dumps byte-identical | `spec/integration/postgresql_round_trip_spec.rb`; `bss:round_trip` in the MySQL and SQLite integration apps (CI) |
| Generated SQL is exact, not approximately right | generator specs assert the whole statement (`spec/generators/`) |
| Every supported Ruby, Rails and PostgreSQL major still works | the `matrix` job of `.github/workflows/ci.yml`; the monthly canary for the next ones |
| The gem builds, installs and loads without Bundler | the `package` job of CI |
| Local green means CI green: CI runs the full `bin/check` and `bin/repo-guards` | `bin/repo-guards` |
| Agent-read files carry no HTML comment or invisible character; `CLAUDE.md` under 12,000 characters | `bin/repo-guards` |
| Actions pinned to a commit SHA, narrow permissions | actionlint and zizmor in the `workflows` job (`.github/zizmor.yml`) |
| ZIP extraction keeps its traversal, count and size limits | specs for `lib/better_structure_sql/zip_generator.rb`; the reviewer |
| The web UI escapes stored content and fails closed | request and controller specs (`spec/requests/`, `spec/controllers/`); the reviewer |
| Quoted SQL, sorted introspection, adapter parity, no swallowed errors | the reviewer (`.dz/maintainer/reviewer.md`), agent `dump-reviewer` |
| A release is a merged version bump, never a manual push or tag | `.github/workflows/release.yml`, `RELEASE.md` |
| One concern per pull request; a body that claims only what the diff does; `CHANGELOG.md` for user-visible changes | the reviewer, `.github/PULL_REQUEST_TEMPLATE.md` |
