# .github/ — CI, canary, release

Outside contributors do not change `.github/`, `bin/`, the gemspec or `VERSION` (owner only; dependency-bot bumps exempt): `.dz/maintainer/maintainer.yml`.

## Workflows

| File | Trigger | Does |
|---|---|---|
| `workflows/ci.yml` | pull request, push to `main`, manual, `workflow_call` from `release.yml` | The gate. Ends in the aggregate job **`CI OK`** |
| `workflows/canary.yml` | monthly cron, manual | Ruby head, Rails edge, `postgres:latest`. **Not** part of `CI OK`; the monthly `improve` checkup (`.dz/schedules/improve.md`) reads it |
| `workflows/release.yml` | push to `main` touching `lib/better_structure_sql/version.rb`, manual on `main` | Verify, publish, tag, GitHub Release |
| `workflows/deploy-docs.yml` | `site/**` or `version.rb` on PR and `main` | `npm ci`, lint, test, build in `site/`; deploys GitHub Pages from `main` only |
| `dependabot.yml` | weekly | Grouped updates (bundler for the gem and the three integration apps, actions, npm for `site/`, docker) with a cooldown. The maintainer agent is the only merger; there is no auto-merge workflow |
| `zizmor.yml` | - | Reviewed exceptions for the workflow security linter |
| `scripts/changelog-notes.sh <version>` | called by `release.yml` | Prints that version's `CHANGELOG.md` section; fails when missing or empty |

## `ci.yml` jobs

| Job | Checks |
|---|---|
| `workflows` | actionlint + zizmor on `.github/workflows`; `bin/repo-guards` |
| `locked` | The committed `Gemfile.lock` and `.ruby-version`, twice: PostgreSQL runs `bin/check` (RuboCop + RSpec, the local gate); SQLite runs `bundle exec rspec` on the in-memory default of `config/database.yml` |
| `matrix` | rspec on `gemfiles/matrix.gemfile` (unlocked, `RAILS_VERSION`): each supported Ruby, Rails and PostgreSQL major at least once, not the cross product |
| `integration-postgresql`, `integration-mysql` | In the app: migrate from scratch (dumps through the gem), assert `db/schema/_manifest.json`, then `db:drop db:create db:schema:load db:schema:dump` |
| `integration-sqlite` | Migrate and `db:schema:dump_better`, assert `db/structure/_manifest.json` |
| `package` | `gem build --strict`, install into an empty `GEM_HOME` without Bundler, `require` it |
| `ci-ok` (`CI OK`) | Fails unless every job above succeeded; skipped or cancelled counts as failed |

Rules:

- **Branch protection requires only `CI OK`.** A new job must be added to `ci-ok`'s `needs`, or it gates nothing. Live ruleset: `gh api repos/sebyx07/better_structure_sql/rulesets`.
- `bin/repo-guards` (run by `bin/check` and by the `workflows` job) fails when `ci.yml` stops running the full `bin/check`, when a file agents read (`CLAUDE.md`, `AGENTS.md`, `.claude/**`, `llms.txt`, `.mcp.json`) holds a zero-width or bidi character or an HTML comment, when committed settings set `ANTHROPIC_BASE_URL` or `enableAllProjectMcpServers`, or when the root `CLAUDE.md` reaches 12,000 characters.
- `bin/check` **is** the PostgreSQL leg of `locked` (the only place RuboCop runs in CI). It does **not** run the matrix, the SQLite leg, the integration apps, the package build or the workflow linters. Green locally can still be red in CI; read the failed job, its log names the command.
- The matrices in `ci.yml` and `canary.yml` are the only place supported versions are listed. Docs link here; never copy the list.
- Version floors change in three places together: the gemspec, the lowest `matrix` row, `CHANGELOG.md` (breaking).
- Actions are pinned to a commit SHA with the version in a trailing comment; `persist-credentials: false` on checkout; top-level `permissions: contents: read`, widened per job only. zizmor fails the build otherwise. A new exception goes in `zizmor.yml` with the reason.
- The integration apps install unfrozen on purpose: their lockfiles pin the path-sourced gem's version, which every release bumps.
- Editing a workflow: `docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint:<version in ci.yml> -color` before pushing.
- A red canary never blocks a PR; fix it in its own PR before the upstream release ships.

## Release lane

Source of truth: `RELEASE.md`. Prepare with `/release` (`.claude/commands/release.md`).

1. PR titled `release: <version>`: bump `VERSION` in `lib/better_structure_sql/version.rb`; move `## [Unreleased]` in `CHANGELOG.md` into `## [<version>] - YYYY-MM-DD`, leaving an empty `Unreleased`; `bundle install` to refresh the gem's own version in `Gemfile.lock`. Check: `.github/scripts/changelog-notes.sh <version>`.
2. `CI OK` green, merge. **The merge is the release.**
3. `release.yml`: `version` (reads `VERSION`, asks rubygems.org and GitHub what already exists; a stray tag on another commit fails the run) -> `verify` (the whole `ci.yml`) -> `publish` (RubyGems trusted publishing, OIDC, environment `release`, no API key) -> `github-release` (tag `v<version>`, notes from the CHANGELOG, `.gem` attached).

Rules:

- Never `gem push`, `rake release`, or push a `v*` tag. The tag is an output of the release, created after RubyGems has the gem.
- A merge that does not change `version.rb` publishes nothing. Do not write "released" in a PR or issue until the gem is on rubygems.org: `gem info better_structure_sql --remote`.
- A published version is never pushed again. Failed before the push: fix on `main`, same version. Failed after the push: run the workflow by hand on `main` before the next bump merges; it skips verify and publish, tags the commit that set `VERSION` (not `main`'s head) and attaches the gem fetched from RubyGems. Broken release: the owner yanks it, then a new patch version.
- Prerelease: RubyGems form `1.0.0.rc1`, tagged `v1.0.0-rc1`.
- `deploy-docs.yml` also runs on a `version.rb` change: the site shows the gem version.
- The weekly `release-due` checkup (`.dz/schedules/release-due.md`) decides when a release PR is opened; `security-release` covers confirmed security fixes on the other days.
- A breaking change needs the owner's decision before merge, and an `### Upgrading` entry in the CHANGELOG.
