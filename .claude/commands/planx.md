---
description: Write a concise, self-contained implementation plan to docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>/ for another agent to execute. Plan only — no source edits. Use for planx, plan this, design before building.
argument-hint: [the change you want planned]
---

# /planx

Plan only. No implementation, no edits outside the plan dir. The executor reads `overview.md`, its own slice, and the files those cite — nothing else.

Skip it for small work: a one-file fix does not need a plan dir.

## Goal
$ARGUMENTS

## Steps

1. **Resolve the path.** `date +%Y`, `date +%m`, `date +%d`. `ls -d docs/plans/<YYYY>/<MM>/<DD>/1*` → next number = highest `1NN-*` + 1, else `101`. Slug = kebab-case, max 5 words. Plan dir: `docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>/`.

2. **Explore, read-only, in this checkout.** Fan out Explore agents over disjoint areas when the change is broad. Record everything the executor would otherwise search for, as `file:line | pattern`:
   - the nearest existing feature to mirror: introspection in `lib/better_structure_sql/introspection/`, generator in `lib/better_structure_sql/generators/`, wiring in `lib/better_structure_sql/dumper.rb`
   - adapter impact: `lib/better_structure_sql/adapters/{postgresql,mysql,sqlite}_adapter.rb` — which adapters gain the feature, which degrade gracefully
   - config surface: `lib/better_structure_sql/configuration.rb`, the initializer template under `lib/generators/`
   - specs to mirror: `spec/generators/`, `spec/adapters/`, `spec/integration/`
   - user-facing docs that go stale: `README.md`, `docs/`, `site/src/pages/`, `CHANGELOG.md`

3. **Write the plan as multiple files** — never one `plan.md`.

   `overview.md`: **Goal** (1–2 sentences, what + why) · **Context** (only the facts the executor needs + reference patterns at `file:line`) · **Plan files, in execution order**, one-line hook each · **Done when** (verifiable: named specs green, `bin/check` green, dump output deterministic across two runs) · **Risks / open questions**.

   One `<NN>-<aspect>.md` per separable area of work, e.g. `01-introspection.md`, `02-generator.md`, `03-dumper-wiring.md`, `04-adapters.md`, `05-docs.md`. Each carries: `> Part of overview.md. Depends on: <NN or none>` · **Files to change** (`path:line` — what, why) · **Steps** (ordered, concrete) · **Tests** (what to add, and `bin/check files <paths>`) · **Done when**.

4. **Write `status.yml`** in the plan dir — the only tracker:

```yaml
plan: <1NN>-<slug>
title: <human title>
status: not_started        # not_started | in_progress | blocked | complete | superseded
created_by: <git config user.name>
worked_by: ""              # executor fills with their git user.name
owner: <git config user.name>
percent: 0
current_focus: ""
slices:
  - { file: 01-<aspect>.md, status: not_started, percent: 0 }
evidence: []               # commits / PRs
works: []                  # confirmed only, each with its proof (spec, PR)
tried_failed: []           # approach + exact reason; the next session does not retry these
deviations: []             # what departed from the plan + why
next_step: ""              # exact: file, method, pattern to mirror
last_updated: <YYYY-MM-DD>
```

## Rules

- **Slices are path-disjoint.** A slice boundary is the file set one agent locks in `/feature`, and one PR. Two slices that must edit the same file are one slice.
- Reference, don't restate: `file:line`, `Class#method`. Never paste code — it goes stale immediately.
- No checkboxes in the `.md` files. `status.yml` is the only tracker.
- Tests are part of the slice that changes the behaviour, not a trailing slice of their own.
- Never plan a `git worktree` step or an `isolation: worktree` agent — execution happens in this one checkout.
- Never plan a manual release step: releases happen by merging a version bump (`/release`).

## Output
```
✓ docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>/overview.md
  + 01-<aspect>.md, 02-<aspect>.md, …
  + status.yml
Next: /feature docs/plans/<YYYY>/<MM>/<DD>/<1NN>-<slug>
```
