# `.dz/`

Repo-scoped configuration for the [developerz.ai](https://developerz.ai) maintainer agent, which runs
this repository as an AI-managed project.

- `maintainer/maintainer.yml`: the maintainer policy (triage, PRs, review, releases, schedules).
- `maintainer/reviewer.md`: this repo's layer of the reviewer prompt (what to reject, what never to flag).
- `pipeline/agent-pipeline.json`: the agent pipeline definition.
- `schedules/`: the scheduled checkup briefs (`release-due`, `security-release`, `health`, `improve`) the policy fires.
- `onboarding/scorecard.md`: the AI-first scorecard; each onboarding run rewrites it.

Releasing is merging a `lib/better_structure_sql/version.rb` bump to `main`: `release.yml` publishes
the gem through RubyGems trusted publishing, then tags it. Nobody tags or `gem push`es by hand.

Agent instructions for working on the code live in `CLAUDE.md`. The gate is `bin/check` locally and
the `CI OK` check on GitHub; both need PostgreSQL.
Docs: https://developerz.ai/docs/maintainer-yml
