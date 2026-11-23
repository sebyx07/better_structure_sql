# Brief: is the project healthy?

Daily checkup, fired by `schedules: health` in `.dz/maintainer/maintainer.yml`. better_structure_sql is
maintained so that nobody has to watch it. This covers the failures no issue or PR announces.
Read-only (a scout): it reports failing rows, it never re-runs a publish, tags, or pushes. A row
whose only fix is under `.github/` or `.dz/` is stated in the run's answer instead of filed: the
platform refuses a checkup filing that names CI or policy paths, and the monthly `improve` task
(`.dz/schedules/improve.md`) or the owner picks it up from there.

```bash
R=sebyx07/better_structure_sql
v=$(gh api "repos/$R/contents/lib/better_structure_sql/version.rb" --jq .content | base64 -d | sed -n "s/.*VERSION = '\(.*\)'.*/\1/p")
# The tag release.yml creates: RubyGems prerelease 1.0.0.rc1 is tagged v1.0.0-rc1.
tag="v$(echo "$v" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.(.+)$/\1-\2/')"
```

| Signal | Command | Healthy |
|---|---|---|
| `main` is green | `gh run list -R $R --workflow ci.yml --branch main --event push --limit 1 --json conclusion,headSha,url` | `success` (the `CI OK` job passed) |
| the last release published | `gh run list -R $R --workflow release.yml --limit 1 --json conclusion,displayTitle,url,createdAt` | `success`, or no run yet, or one in progress |
| RubyGems serves `BetterStructureSql::VERSION` | `curl -s -o /dev/null -w '%{http_code}' "https://rubygems.org/api/v2/rubygems/better_structure_sql/versions/$v.json"` (this exact version, so a prerelease counts; `latest.json` skips prereleases) | `200`; or `404` while a `release.yml` run for `$v` is in flight or under 2 h old. Any other code is a failed read, not a verdict |
| the release is tagged | `gh api "repos/$R/git/ref/tags/$tag" --jq .ref` and `gh release view "$tag" -R $R --json tagName` | both exist once RubyGems serves `$v` |
| the docs site deploys | `gh run list -R $R --workflow deploy-docs.yml --branch main --event push --limit 1 --json conclusion,url,createdAt`, `gh api repos/$R/pages --jq .build_type` and `curl -fsS -o /dev/null -w '%{http_code}' https://sebyx07.github.io/better_structure_sql/` | the run is `success` (both jobs: `build`, then `deploy` to the `github-pages` environment), `build_type` is `workflow` (Pages is served by the Actions deploy, there is no `gh-pages` branch), and `200`. Pull-request runs of this workflow build only and deploy nothing: they are not this row |
| Dependabot is not stuck | `gh pr list -R $R --author app/dependabot --state open --json number,title,createdAt,statusCheckRollup` | none open more than 7 days, none red more than 2 days |
| canary ran | `gh run list -R $R --workflow canary.yml --limit 1 --json conclusion,createdAt,url` | a run in the last 35 days (its failures are the monthly `improve` checkup's job, not this one's) |

If a workflow named above does not exist yet (`gh workflow view <file> -R $R` fails), that is the
row, not an error in this brief.

## Rows

Each failing row is filed once, with the exact title below, unless an open issue with that title (or the
same title prefix for rows with a variable) already exists: `gh issue list -R $R --state open --search '"<title>" in:title'`.
The body carries the command, its output and the run URL. A red `main` comes first: nothing
releases from it.

- `main-red` — title `main is red at <short sha>`: the last push run of `ci.yml` on `main` did not conclude `success`. If an older open `main is red at …` issue names another sha, or `main` is green again while one is open, say so in the answer with the run URL (this run closes nothing).
- `release-unpublished` — title `release v<version> did not publish`: the last `release.yml` run did not conclude `success`.
- `rubygems-version-lag` — title `RubyGems does not serve <version>`: RubyGems answers 404 for `$v` and no release run is in flight or under 2 h old.
- `release-untagged` — title `<tag> is published but not tagged`: RubyGems serves `$v` but the `$tag` tag or GitHub release is missing.
- `docs-deploy-red` — title `docs site deploy is failing`: the last `deploy-docs.yml` push run on `main` failed, Pages is not built by the workflow (`build_type` is not `workflow`), or the site does not answer 200.
- `dependabot-stuck` — title `Dependabot PR #<n> is stuck`: a Dependabot PR open more than 7 days, or red more than 2 days. Say why it is stuck (red check, conflict, waiting on review) in the body.
- `canary-stale` — title `canary has not run in 35 days`: no `canary.yml` run in the last 35 days, or the workflow is missing.

Never delete a tag, re-run a publish, `gem push` or push to `main` from here.
