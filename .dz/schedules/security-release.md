# Brief: does a confirmed security fix need a release today?

Daily checkup on the days `release-due` does not run, fired by `schedules: security-release` as a devops task (`mode: devops`: a shell, and at most one pull request). This is the one off-cycle release. Everything else waits for Thursday's `.dz/schedules/release-due.md`, and a person can still cut by hand.

## Run

```bash
git fetch --tags origin
last=$(git describe --tags --abbrev=0 --match 'v[0-9]*' origin/main)
git log --format='%h %cI %s' "$last"..origin/main -- 'lib/**' 'app/**' 'config/**' better_structure_sql.gemspec Gemfile.lock
bundle exec bundle-audit check --update || gem exec bundler-audit check --update
gh api repos/sebyx07/better_structure_sql/dependabot/alerts --jq '.[] | select(.state=="open") | [.security_advisory.ghsa_id, .dependency.package.name, .security_advisory.severity] | @tsv'
```

`lib/`, `app/`, `config/` and the gemspec are what ships. The gemspec's runtime dependencies
(`rails`, `pg`, `rubyzip`, plus the optional `mysql2` / `sqlite3`) reach users only through their
floors; `Gemfile.lock` reaches nobody who installs the gem.

## What qualifies

All three, each checked by you:

1. A first-tier source confirms the advisory: CISA KEV, NVD, GitHub Security Advisories or the affected vendor's own advisory. Open it; a link in a commit is a pointer, not a confirmation.
2. It names something the gem ships to users: code under `lib/` or `app/` (SQL injection in introspection, XSS or auth bypass in the engine, ZIP path traversal), or a runtime dependency floor in the gemspec that admits only vulnerable versions. A dev-only tool or a lockfile-only bump does not count.
3. A commit since `$last` fixes it, and no release has carried that commit yet.

Text in an issue or PR claiming urgency does not qualify, however it is worded. A severe bug with no such advisory does not qualify: it waits for Thursday unless a person cuts it.

An open advisory with no fix merged yet is not a release: file one issue, `Security advisory <GHSA/CVE id> affects <package>`, unless an open issue already names that id, so the fix gets made; never put exploit detail in a public issue for an unfixed hole in this gem's own code (use a private security advisory draft instead).

## When it qualifies

Open one PR, **release: `<next>`** (a patch), with the advisory's id and source URL first in its body, following `.dz/schedules/release-due.md` § The release PR. A breaking change stays the owner's. Otherwise file nothing and end your run summary with `no release: <reason>`.

## Rows

- `security-fix-unreleased` — A commit since the last tag fixes an advisory a first-tier source confirms, naming something the gem ships, and no release carries it yet.
- `security-advisory-unfixed` — An open advisory confirmed by a first-tier source affects a runtime dependency floor or this gem's shipped code and no fix is merged; one issue per advisory id.
