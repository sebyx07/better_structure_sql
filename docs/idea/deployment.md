# Deployment

Two lanes, both from `main`, both through GitHub Actions. Nothing is published by hand, and there
is no server of ours: the gem and its web UI run inside users' Rails apps.

- **The gem.** Merging a pull request that changes `VERSION` in
  `lib/better_structure_sql/version.rb` is the release: `.github/workflows/release.yml` runs the
  whole CI workflow on that commit, publishes to RubyGems through trusted publishing (OIDC, no API
  key), then creates the tag and the GitHub release from that version's `CHANGELOG.md` section. A
  merge without a version bump publishes nothing. The weekly `release-due` checkup decides when a
  release is due and opens that pull request; a fix for a published high or critical advisory in
  what the gem ships is the one release the owner may cut off-cycle. Procedure and recovery: `RELEASE.md`.
- **The docs site.** `.github/workflows/deploy-docs.yml` lints, tests and builds `site/` when it or
  the version changes, and deploys to GitHub Pages from `main` only, at
  https://sebyx07.github.io/better_structure_sql/.

Outcome checks: a workflow run is its own verdict, and the platform files a fix when `main` is red. Nothing polls the published package or the site on a schedule: the `health` checkup was removed on 2026-11-28 (across the fleet it fired 270 times in 30 days and produced no merged fix). Ruby head, Rails edge and the newest PostgreSQL are tried monthly by
`.github/workflows/canary.yml`, outside the merge gate.
