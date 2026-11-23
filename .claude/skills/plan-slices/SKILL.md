---
name: plan-slices
description: Use when asked to plan, design or break down a change in better_structure_sql before building it — plan dir, slices, status.yml, planx, "write a plan", resuming work from docs/plans.
---

# Plan in path-disjoint slices

The full procedure and file templates are in `.claude/commands/planx.md` — read it and follow it. The rules that matter most:

1. Plans are files: `docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>/` with `overview.md`, one `<NN>-<aspect>.md` per separable area, and `status.yml`. Never one `plan.md`.
2. Plan only — write nothing outside the plan dir.
3. Slices are path-disjoint: a slice is the file set one agent locks and one PR. Two slices editing one file are one slice. Usual cut for this gem: introspection · generator · dumper wiring · adapters · docs.
4. Point at code with `file:line`; never paste it.
5. `status.yml` is the only tracker — no checkboxes in the `.md` files. `tried_failed` gets the approach and the exact reason, written the moment it dies.
6. Resuming: read `status.yml` first, check it against `git log` (a slice may have shipped already), then execute `next_step`.
7. One-file fix → no plan; just do it.
8. Never plan a git worktree or a manual release step.
