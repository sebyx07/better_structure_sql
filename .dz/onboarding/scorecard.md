# AI-first scorecard

> This card is the repository's own — established by the developerz.ai maintainer agent for the maintainers of this repository; each onboarding run rewrites the file whole, the latest run wins, and the same card is stored on the platform.

- Run: `run_8346fc6783c54c1db4a8db86ca6f01da`
- Computed: 2026-11-23T08:19:55.040Z
- Proof: **proved** — every command ran green at head.
- Score: 14 of 15 items ok

## `policy` — ok

- .dz/maintainer/maintainer.yml already present, left alone
- .dz/maintainer/reviewer.md already present, left alone

## `brain` — ok

- CLAUDE.md already present, left alone

## `roster` — ok

- .claude/agents already present, left alone

## `skills` — ok

- .claude/skills already present, left alone

## `scripts` — ok

- bin/setup already present, left alone
- bin/dev already present, left alone
- bin/check already present, left alone
- bin/stop already present, left alone
- down: ./bin/stop (bin)
- ./bin/setup exited 0 at head (1.2s)

## `wiring` — ok

- .mcp.json established

## `commands` — ok

- .claude/commands already present, left alone

## `access` — ok

- asked for 0 credentials
- ./bin/check exited 0 at head (11.7s) without one

## `layout` — gap

- migration to the house layout filed as tasks
- apps/better-structure-sql: 27 move(s) planned as one task

## `smoke_test` — ok

- spec/integration/postgresql_round_trip_spec.rb in the repository
- run by ./bin/check exited 0 at head (11.7s)

## `env_example` — ok

- .env.example established

## `agents_md` — ok

- AGENTS.md already present, left alone

## `per_workspace_brains` — ok

- integration/CLAUDE.md established
- integration_mysql/CLAUDE.md established
- integration_sqlite/CLAUDE.md established
- site/CLAUDE.md established

## `docs_readme` — ok

- docs/README.md already present, left alone

## `gate_proved` — ok

- ./bin/check exited 0 at head (11.7s)
