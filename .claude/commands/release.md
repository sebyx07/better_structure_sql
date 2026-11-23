---
description: Prepare a better_structure_sql release pull request — bump version.rb, move CHANGELOG Unreleased into a dated section, verify, open the PR. Merging that PR publishes the gem through CI. Use for release, publish, ship a version, bump the gem version.
argument-hint: [major|minor|patch|auto|X.Y.Z]
---

# /release

**Merging a version bump into `main` is the publish action.** `.github/workflows/release.yml` sees the new `BetterStructureSql::VERSION`, publishes to RubyGems with OIDC trusted publishing (no API key anywhere), then tags and creates the GitHub release. Your job ends at an open, green release PR — plus the merge when the user asked for it.

`RELEASE.md` is the source of truth for the pipeline; read it first, and follow it where it differs from this file.

## Target version
$ARGUMENTS (default `auto`)

| Bump | When (`auto` reads `git log v<current>..HEAD --oneline` and `## [Unreleased]`) |
|---|---|
| major | breaking: removed/renamed config or public API, incompatible dump output. Needs the owner's explicit go-ahead. |
| minor | new feature, new adapter capability, new rake task or config option |
| patch | fixes, docs, internal refactors only |

## Steps

1. **Preflight** — any failure → stop and report.
   - `git fetch origin && git status --short` clean, on an up-to-date `main`
   - `gh run list --branch main --limit 1` is green
   - `## [Unreleased]` in `CHANGELOG.md` is non-empty; empty → draft entries from `git log v<current>..HEAD` and get approval
   - the version is unused: `git tag -l vX.Y.Z` prints nothing and `gem list -r better_structure_sql --all` does not list X.Y.Z
2. **Branch:** `git checkout -b release/X.Y.Z`. No other release PR may be open: `gh pr list --search 'release: in:title' --state open` prints nothing.
3. **Bump:**
   - `lib/better_structure_sql/version.rb` → `VERSION = 'X.Y.Z'`
   - `CHANGELOG.md` → rename the filled `## [Unreleased]` to `## [X.Y.Z] - <date +%F>`, drop its empty subsections, add a fresh empty `## [Unreleased]` (Added / Changed / Fixed) above it
   - `bundle install` → refreshes the gem's own version in `Gemfile.lock`
   - every other mention of the old version: `git grep -n -F '<old version>' -- ':!CHANGELOG.md' ':!*.lock' ':!site/package-lock.json'` (expect `site/package.json`, sometimes README or `site/src/pages/GettingStarted/`); `site/package.json` changed → `npm --prefix site install --package-lock-only`
4. **Verify:** `bin/check` green, then `gem build better_structure_sql.gemspec` builds without warnings; delete the built `.gem` file.
5. **PR:** one commit `release: X.Y.Z` containing only the bump. `git push -u origin HEAD`, then `gh pr create --title "release: X.Y.Z"` with the new changelog section as the body. The title is a contract: the `release-due` checkup finds an open release PR by it. `gh pr checks --watch`.
6. **Merge** only on green and only when the user asked for the release to go out: `gh pr merge --squash --delete-branch`. Then watch the publish: `gh run watch $(gh run list --workflow release.yml --limit 1 --json databaseId --jq '.[0].databaseId')`.
7. **Confirm:** `gem list -r better_structure_sql` shows X.Y.Z and `gh release view vX.Y.Z` exists. Report both, or report exactly which job of `release.yml` failed and apply `RELEASE.md` § If a release fails:
   - failed before the gem was pushed: fix on `main`, keep the same version; the next push touching `version.rb` or `gh workflow run release.yml --ref main` starts over
   - the gem is on RubyGems but the tag or GitHub release is missing: `gh workflow run release.yml --ref main` before any other version bump merges; it skips verify and publish
   - the published gem is broken: tell the user; the owner yanks it, and the fix ships as a new patch version

## Never

- Never `gem push`, never `rake release`, never `gem yank` (yanking is the owner's call).
- Never create or push a `v*` tag — `release.yml` owns tagging.
- Never reuse a version number that reached RubyGems. A version that never got there keeps its number.
- Never mix feature work into the release PR.
