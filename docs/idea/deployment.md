# Deployment

Two lanes, both from `main`, both through GitHub Actions. Nothing is published by hand, and there
is no server of ours: the gem and its web UI run inside users' Rails apps.

- **The gem.** Merging a pull request that changes `VERSION` in
  `lib/better_structure_sql/version.rb` is the release: `.github/workflows/release.yml` runs the
  whole CI workflow on that commit, publishes to RubyGems through trusted publishing (OIDC, no API
  key), then creates the tag and the GitHub release from that version's `CHANGELOG.md` section. A
  merge without a version bump publishes nothing. The weekly `release-due` checkup decides when a
  release is due and opens that pull request; `security-release` covers confirmed security fixes
  on the other days. Procedure and recovery: `RELEASE.md`.
- **The docs site.** `.github/workflows/deploy-docs.yml` lints, tests and builds `site/` when it or
  the version changes, and deploys to GitHub Pages from `main` only, at
  https://sebyx07.github.io/better_structure_sql/.

Outcome checks: the daily `health` checkup (`.dz/schedules/health.md`) verifies that `main` is
green, the last release run succeeded, RubyGems serves the current version, the release is tagged
and the site answers. Ruby head, Rails edge and the newest PostgreSQL are tried monthly by
`.github/workflows/canary.yml`, outside the merge gate.
