# AI-first scorecard

> Hand-written for the AI-maintenance onboarding pass of 2026-11-22, describing the repository as
> it stands once that pass's pull request merges. The next developerz.ai onboarding run rewrites
> this file whole; the latest run wins, and the same card is stored on the platform.

- Computed: 2026-11-22
- Proof: **not yet proved** — written before the pass merged; items marked *pending* depend on
  sibling changes in the same pass and must be re-checked at head.
- Score: 6 of 15 items ok, 7 pending, 2 gap

## `policy` — ok

- .dz/maintainer/maintainer.yml established (validates against maintainer.v1.json)
- .dz/maintainer/reviewer.md established
- .dz/schedules/{release-due,security-release,health,improve}.md established
- .dz/pipeline/agent-pipeline.json established

## `brain` — pending

- CLAUDE.md present, being rewritten in this pass (today it documents a section order and
  directory names, `1_extensions`, that differ from `FileWriter::SECTION_DIRECTORIES`)

## `roster` — ok

- .claude/agents/schema-export-specialist.md present

## `skills` — gap

- no .claude/skills/
- .claude/commands/release.md describes a manual build-and-push release, which the policy forbids
  (merging a version bump is the release); it must be rewritten or removed

## `scripts` — pending

- bin/setup, bin/check, bin/dev, bin/stop being added in this pass
- bin/check exits 75 when PostgreSQL is unreachable, matching `services: [postgres]`

## `wiring` — gap

- no .mcp.json

## `commands` — ok

- .claude/commands/feature.md present

## `access` — ok

- no secrets needed: RubyGems publishing is OIDC trusted publishing (no API key)

## `layout` — ok

- single gem at the root; integration apps under integration*/; docs site under site/

## `smoke_test` — pending

- spec/integration/ present; a round-trip (dump, load, re-dump, diff) spec is the `improve`
  checkup's first determinism row if none lands in this pass

## `env_example` — pending

- no .env.example yet; bin/check documents DATABASE_URL and its default

## `agents_md` — pending

- no AGENTS.md / llms.txt yet (llms.txt is referenced by the reviewer and improve briefs)

## `per_workspace_brains` — ok

- single-package repository: integration*/ and site/ are samples and docs, not packages

## `docs_readme` — pending

- no docs/README.md index yet

## `gate_proved` — pending

- `CI OK` aggregate job, canary.yml, dependabot.yml and version-bump-triggered release.yml are
  being added in this pass; until they merge, ci.yml has no `CI OK` job and release.yml still fires
  on a pushed tag
