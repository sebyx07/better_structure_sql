# Devops checkup

Weekly checkup, Saturdays 08:00 UTC, OFFERED and off: the `devops` entry in
`.dz/maintainer/maintainer.yml` is commented out, and uncommenting it is the opt-in. It is the
developerz.ai platform's standard devops checkup, adapted to better_structure_sql: how this
repository ships, graded on five axes. A read-only scout: you read files only, no shell, network or
database. You also have the Signals block: recent CI job failures and failed tasks.

What ships here: a Ruby gem (`better_structure_sql`: `lib/`, `app/`, `config/routes.rb`) published
by `.github/workflows/release.yml` through RubyGems trusted publishing when
`lib/better_structure_sql/version.rb` changes on `main`, and the docs site (`site/`) published to
GitHub Pages by `.github/workflows/deploy-docs.yml`. There is no server of ours: the gem and its
web UI engine run inside users' Rails apps. The Dockerfiles and compose files are the development
environment only.

**Evidence or nothing.** Every point lost names a `path:line` or a Signals line. A number you
cannot read is reported as `not read`, never an estimate, and a finding whose harm depends on a
size or a rate you cannot see is marked `measure first: yes`. Do not fix what is not broken.

## The axes

1. **Reliable.** Does a change get proved before it ships, and can a bad one be undone?
   - `bin/check` and CI run the same gate (the `locked` job of `ci.yml` runs `bin/check` on
     PostgreSQL; the aggregate `CI OK` job needs every other job), and `release.yml` runs that
     whole workflow before the gem is pushed.
   - `Gemfile.lock` is committed and agrees with `Gemfile` and the gemspec; Ruby is pinned by
     `.ruby-version`; the floors live in the gemspec and the lowest CI matrix row tests them.
   - The round-trip oracle (`spec/integration/postgresql_round_trip_spec.rb`) and the integration
     apps' `bss:round_trip` still run in CI.
   - A bad release can be undone: `RELEASE.md` says how (the owner yanks the version and a new
     patch ships; a published version is never pushed again).
   - Signals: the same CI job or task failure kind recurring. Report the counts as they stand.
2. **Secure.** What could leak, or run that nobody reviewed?
   - A secret, token or RubyGems credential committed to the tree. Quote the key and path, never
     the value. Publishing is OIDC: a stored RubyGems API key anywhere is a finding. The
     `postgres:postgres` defaults of the local container and CI services are documented test
     credentials, not a finding.
   - Third-party actions pinned to a full commit SHA; workflow `permissions` declared and narrow;
     no `pull_request_target`; `persist-credentials: false` on checkout.
   - In the gem: introspection SQL built by interpolating an unquoted name or value; the engine
     rendering stored schema content unescaped, or a controller without `authenticate_access!`;
     ZIP extraction without the traversal, file-count and size limits (`zip_generator.rb`).
3. **Fast.** How long does a change wait for its answer?
   - CI that repeats work: serial jobs that could run side by side, a step rebuilding what an
     earlier one built, a job installing gems without the bundler cache. The integration apps
     install unfrozen on purpose (`.github/CLAUDE.md` says why): not a finding.
   - Superseded CI runs left running (`concurrency`).
4. **Efficient.** What does this repository carry that it does not use?
   - A gem in `Gemfile` or the gemspec nothing requires, two gems doing one job, a file in the
     packaged gem (`spec.files` in the gemspec) that users never load.
   - A generated artifact committed beside its source (a built `*.gem`, `pkg/`, the site's build
     output). The dumps under `integration/db/schema/` are fixtures CI loads: not a finding.
5. **Cheap.** What costs money every day without paying for itself?
   - A scheduled workflow or checkup far more frequent than its result is read; a test matrix wider
     than the versions supported (the matrix is one row per supported major, not a cross product,
     by design).
   - Workflow artifacts or Pages builds kept with no expiry.
   - Money is almost always `measure first: yes`: name what to measure, never a price you did not
     read.

**CI configuration is graded, never filed.** Read workflow files to score the axes, and report what
you find in your answer. Never name a CI configuration file in a handoff, nor a secret-shaped path:
a handoff naming one is refused whole.

## Rows

One per axis; a handoff reports one failing row.

- `reliable`: a change can ship unproved, or cannot be undone
- `secure`: something can leak, or run unreviewed
- `fast`: a change waits on avoidable work
- `efficient`: the repository carries what it does not use
- `cheap`: something costs money every day without paying for itself

## How to judge

- Confirm before you claim: read the file that does the thing, not only a file that mentions it.
- Rank by blast radius: what breaks or leaks for users first, money last.
- Skip tests, fixtures, generated and vendored code.
- A check that does not apply to this repository is not a failure.
- One handoff per row: every defect on an axis goes in it, worst first.

## Every finding

Besides the checkup rules' fields, each handoff carries these; one over any limit is dropped whole:

- **work**: one sentence naming the defect and the fix, at most 300 characters.
- **why**: a concrete failure scenario, what triggers it and what breaks, at most 300 characters.
- **evidence**: at most 10 lines of at most 280 characters each. One line `path:line: the code` per
  site. The last line starts `measure first:`. Write `measure first: no` with the reason when the
  file alone proves the harm, or `measure first: yes` with what to measure and how.
- **paths**: at most 20 files.
- **anchor**: the row id (`reliable:`, `secure:`, `fast:`, `efficient:` or `cheap:`), then the
  worst file or symbol, at most 120 characters.
- **metric**: the number the fix moves, at most 200 characters.

## Report

First the score, then the findings.

For each axis, `N of 5` or `not read`: 5 means you looked and nothing failed, and each failing check
costs a point. One line per point lost, with its evidence. Then the total, `N of 25`, or `N of M
over K axes read`, with the change since the last checkup when the Signals block names one.

Then the finding list, worst first: every point lost, including the CI configuration ones no handoff
may carry. Name anything you could not cover, and why.
