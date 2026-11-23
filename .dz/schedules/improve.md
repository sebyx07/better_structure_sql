# Brief: monthly improvement

Fired on the first Tuesday of the month (UTC days 1-7, `weeks_of_month: [1]`) by `schedules: improve`
in `.dz/maintainer/maintainer.yml`, after `canary.yml`'s run on the 1st. It runs as a devops task
(`mode: devops`): a shell on a checkout, delivering one pull request.

better_structure_sql is maintained by agents only. Once a month, leave it measurably better and one
step ahead of the next PostgreSQL, MySQL, SQLite, Rails and Ruby release. Read `CLAUDE.md` first:
its invariants (pure Ruby, no external binaries, deterministic output, structure only, fixed section
load order, adapter parity, quoted introspection SQL) bind every change. `bin/check` must be green
before any PR.

## Rows

- `canary-red`: the latest `canary.yml` run (Ruby head, Rails edge, newest PostgreSQL) failed, or none ran in the last 35 days (§1).
- `upstream-release`: a new upstream release this gem must track is not yet covered by CI or the canary (§2).
- `determinism-or-roundtrip`: dumping the test schema twice differs, or the dump does not load back into an empty database and re-dump identically (§3).
- `dep-major`: a dependency major Dependabot could not land (§4 item 2).
- `correctness`: an open `bug` issue, an adapter parity gap, or an unquoted introspection query (§4 item 3).
- `docs-drift`: a claim in `README.md`, `CLAUDE.md`, `llms.txt` or `site/` no longer matches the code (§4 item 4).
- `dead-code`: dead code, duplicated logic, or a slow or flaky spec (§4 item 5).

## 1. Canary first

`gh run list --workflow canary.yml --limit 1 --json conclusion,url,createdAt`. If it failed, find the
cause in the log (`gh run view <id> --log-failed`) and fix it here. If the break is upstream and not
ours to fix, open one issue upstream-linked and don't work around it with shims. If no run is younger
than 7 days, start one (`gh workflow run canary.yml`) and read it before step 4.

## 2. Upstream releases this gem tracks

Compare each against what `.github/workflows/ci.yml`, `canary.yml`, `docker-compose*.yml` and the
gemspec cover:

| Upstream | Where to look |
|---|---|
| PostgreSQL majors and minors | `https://www.postgresql.org/support/versioning/` and `curl -s 'https://hub.docker.com/v2/repositories/library/postgres/tags?page_size=100&name=-alpine'` |
| MySQL LTS and innovation | `https://dev.mysql.com/doc/relnotes/mysql/` and `https://hub.docker.com/v2/repositories/library/mysql/tags?page_size=100` |
| SQLite | `https://www.sqlite.org/changes.html`; `curl -s https://rubygems.org/api/v1/versions/sqlite3/latest.json` |
| Rails | `curl -s https://rubygems.org/api/v1/versions/rails.json` (newest stable and pre-releases) |
| Ruby | `https://www.ruby-lang.org/en/downloads/releases/` and `https://cache.ruby-lang.org/pub/ruby/index.txt` |
| rubyzip, pg, mysql2 | `curl -s https://rubygems.org/api/v1/versions/<gem>/latest.json` |

A new PostgreSQL major means: add it to the CI matrix (or the canary first if it is a beta), run
the suite against it, and check the catalog columns the adapter reads still exist (release notes'
"Migration" / "System catalogs" sections). A new Rails or Ruby stable goes into the CI matrix; a
new major of a runtime dependency gets its floor checked in the gemspec. End-of-life versions leave
the matrix; dropping a supported floor (Ruby, Rails, a database) is breaking and escalates.

## 3. Round-trip determinism

On `main`, after `bin/setup` (it starts the Postgres both steps use). Never `bin/rails db:prepare`:
Rails loads a SQL schema through `psql`, which the box need not have. The gem's own loader
(`db:schema:load_better`) is pure Ruby, as in `bin/dev`. It loads structure only, so
`db:environment:set` follows it or the next `db:drop` refuses. `db:drop` in development also drops
the test database: `DB_TEST_NAME` keeps it off the shared `better_structure_sql_test`.

```bash
bin/check files spec/integration/*_spec.rb
cd integration && unset DATABASE_URL && export RAILS_ENV=development DB_HOST=127.0.0.1 DB_PORT=55432 \
  DB_USERNAME=postgres DB_PASSWORD=postgres DB_NAME=bss_improve_rt DB_TEST_NAME=bss_improve_rt_test
bin/rails db:drop db:create db:schema:load_better db:environment:set    # the committed db/schema
export SCHEMA_OUTPUT_PATH=tmp/rt.sql
bin/rails db:schema:dump_better && cp tmp/rt.sql tmp/a.sql
bin/rails db:schema:dump_better && diff tmp/a.sql tmp/rt.sql            # same run twice
bin/rails db:drop db:create db:schema:load_better db:environment:set \
  && bin/rails db:schema:dump_better && diff tmp/a.sql tmp/rt.sql       # load back, re-dump
```

Repeat with `SCHEMA_OUTPUT_PATH=tmp/rt_dir` (multi-file mode; compare with `diff -r`).
Any diff is a `determinism-or-roundtrip` bug: fix the sort or the generator, with a spec that dumps
twice (or loads and re-dumps) and asserts equality.

## 4. Pick at most three improvements, in this order

1. Anything the canary, §2 or §3 found.
2. Dependency majors Dependabot can't do (grouped bumps that failed, Rails majors in `integration*/`).
3. Correctness and safety: open issues labelled `bug`; an adapter capability one adapter has and
   another lacks without a `supports_*?` no-op; any introspection query interpolating an unquoted
   name; an engine view rendering stored content unescaped. Every fix comes with a spec.
4. Docs drift: every claim in `README.md`, `CLAUDE.md`, `llms.txt` and the docs site (`site/`)
   still matches the code: config option names and defaults, rake task names, the multi-file
   directory names and order (`FileWriter::SECTION_DIRECTORIES`), supported versions.
5. Simplification: dead code, duplicated logic, slow or flaky specs.

## 5. Ship

This run delivers one pull request: the highest-ranked improvement, small and reviewable, titled
with what it changes. File each of the others (two at most) as its own ask, with the evidence. The
body gives the evidence: the failing canary log, the upstream release URL, the diff of two dumps,
or the spec that failed before. User-visible changes get a CHANGELOG `## [Unreleased]` entry. Never
bump the version here (the `release-due` checkup does that); a breaking change escalates to the
owner instead of merging.

A change under `.github/` (a matrix row, a new job or step, a workflow) never shares a pull request
with code. Open it on its own and say in the body that it changes CI: the platform's merge gate
proves only an action pinned to a commit SHA or a narrowed permission on the agent's own pull
requests, and holds every other workflow edit for the owner. Never edit `.dz/maintainer/` here.

If nothing is worth changing this month, do nothing: no empty PRs, no churn.
