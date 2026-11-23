# Releasing better_structure_sql

`BetterStructureSql::VERSION` in `lib/better_structure_sql/version.rb` is the
single source of truth. **Merging a pull request that changes it is the
release.** Nobody tags or runs `gem push` by hand: the tag is an output of the
release, created only after RubyGems has the gem.

## Cutting a release

1. Bump `VERSION` (Semantic Versioning; a prerelease uses the RubyGems dot form
   `1.0.0.rc1`, tagged as `v1.0.0-rc1`).
2. In `CHANGELOG.md`, move the `## [Unreleased]` entries into a new
   `## [<version>] - YYYY-MM-DD` section and leave an empty `Unreleased` on top.
   That section's body becomes the GitHub Release notes verbatim, so write it for
   users. Check it: `.github/scripts/changelog-notes.sh <version>`.
3. Run `bundle install`: `Gemfile.lock` records the gem's own version
   (`better_structure_sql (<version>)` under `PATH`), and CI's `locked` job
   installs it frozen, so a stale line fails the gate. Commit the lockfile.
4. `bin/check`, then open the pull request titled `release: <version>` with
   only the bump in it. Let `CI OK` go green, merge.

The title is a contract: the weekly `release-due` checkup looks for an open
pull request titled `release: …` before it opens one.

## What CI does (`.github/workflows/release.yml`)

On a push to `main` that touches `version.rb` (or a manual run on `main`):

1. **version**: reads `VERSION`, asks rubygems.org whether it exists, and checks
   whether the GitHub Release exists. A tag already pointing at another commit
   for an unpublished version fails the run.
2. **verify**: runs the whole CI workflow (`ci.yml`) — only if the gem is not
   on RubyGems yet.
3. **publish**: `gem build` + `gem push` through RubyGems trusted publishing
   (OIDC, environment `release`). Skipped when the version is already on
   RubyGems: a published version is never pushed again.
4. **github-release**: creates tag `v<version>` and the GitHub Release with the
   CHANGELOG notes and the `.gem` attached. After a publish in the same run the
   tag is the commit that was built. When publish was skipped (see below) the
   tag is the newest commit on `main` that set that `VERSION`, and the attached
   `.gem` is downloaded from RubyGems, never rebuilt.

## If a release fails

- Before the gem was pushed: fix on `main` (keep the same version) — the next
  push to `version.rb` or a manual run (Actions → Release → Run workflow, on
  `main`) starts over.
- After the gem was pushed (only the GitHub step failed): run the workflow by
  hand (Actions → Release → Run workflow, on `main`), or re-run the failed job.
  It sees the version on RubyGems, skips verify and publish, and creates the tag
  and release. Commits merged since do not matter: the tag goes on the commit
  that set `VERSION`, and the asset is the gem RubyGems serves. Do this before
  the next version bump merges: the run reads `VERSION` from `main`, so once
  `main` names a newer version the older release has to be created by hand
  (`gh release create v<version> --target <the commit that set it>`).
- A version that reached RubyGems is never pushed again and never reused. A
  broken one is yanked by the owner (`gem yank better_structure_sql -v <version>`)
  and fixed in a new patch version.

## One-time setup

- rubygems.org → better_structure_sql → Trusted publishers → GitHub Actions:
  repository `sebyx07/better_structure_sql`, workflow `release.yml`,
  environment `release`.
- GitHub → Settings → Environments: an environment named `release`
  (deployment branches: `main` only). No secrets are needed.
