---
name: verify-change
description: Use when proving a change in better_structure_sql before a commit or pull request, when bin/check or rspec or rubocop fails, when a script exits 75, or when asked how to run the tests, the linter or the integration app.
---

# Verify a change

`bin/check` is the gate. CI runs the same commands, so green locally is green there.

| Tier | Command | Scope | When |
|---|---|---|---|
| tightest | `bin/check files <paths>` | rubocop on the named Ruby files, rspec on the named `*_spec.rb` | after each edit; the only tier allowed when agents share the checkout |
| fast | `bin/check fast` | `bin/repo-guards` + rubocop on files changed against `origin/main` + unit specs, no database | after a slice works |
| full | `bin/check` | `bin/repo-guards` + rubocop + full rspec against Postgres | once, before the PR |

Other commands: `bin/setup` (install, idempotent) · `bin/dev [--detach]` (integration app, `http://127.0.0.1:3000/better_structure_sql/schema_versions`) · `bin/stop`.

## Exit codes

| Exit | Means | Do |
|---|---|---|
| 0 | green | commit |
| 75 | environment missing — Ruby, gems, docker or Postgres; nothing was graded | `bin/setup`, rerun. Never treat it as a failing change. |
| other | a check ran and is red | read the `failing command` / `rerun` lines at the end of the output |

## Rules

1. Run from anywhere; the scripts `cd` to the repo root and select the Ruby in `.ruby-version` themselves.
2. Changed `Gemfile`, the gemspec or a lock file → `bin/setup` before `bin/check`.
3. Fail one, fix one: rerun only the failing step (`bundle exec rspec --only-failures`, `bundle exec rspec spec/path_spec.rb:LINE`, `bundle exec rubocop -a <file>`), then the tier.
4. Database: default is the `bss-pg` container on `127.0.0.1:55432`, database `better_structure_sql_test`. `DATABASE_URL` overrides it. Sharing the checkout with other agents → `BSS_TEST_DB=bss_<name> bin/check files …` gives you a private database, created on first use.
5. `fast` blind spots: specs that load `rails_helper` and everything under `spec/integration/` do not run. Touched `schema_version*`, the engine in `app/`, `file_writer`, `manifest_generator` → name those specs with `bin/check files`.
6. Write the failing spec first — a green run that never went red proves nothing.
7. Red gate → fix the cause. Never add `rubocop:disable`, loosen `.rubocop.yml`, or mark a spec `skip`/`pending` to get to green.
8. Never trust a piped exit code: `bin/check | tail` reports `tail`. Run it bare, or read `${PIPESTATUS[0]}`.
9. Changed generated SQL → assert the exact text in a spec and check a second dump is byte-identical.
