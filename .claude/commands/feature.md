---
description: Take one change in better_structure_sql from idea to merged — explore, build test-first, prove it with bin/check, open one pull request, watch CI, merge. Use for feature, implement, build it, ship this, fix and merge, execute a plan dir.
argument-hint: <what you want built or fixed, or a docs/plans/… dir>
---

# /feature — idea to merged

**Done means merged with CI green on `main`.** A green local gate is not done; an open PR is not done. Publishing the gem is a separate act (`/release`). Report what you verified, never what you assume happened.

## Request
$ARGUMENTS

**Read autonomy from the prompt.** "Just ship it" → run start to finish, decide everything, surface decisions in the PR body. A tentative ask → clarify what is genuinely ambiguous and stop before merge. Always stop for a real blocker: a breaking change to dump output or the public API, anything touching published releases.

## Steps

1. **Understand.** Restate the goal in one line. A URL or issue is cited → read it first (`gh issue view <n>`). A plan dir is cited → read its `status.yml` first, then `overview.md`, and resume from `next_step`.
2. **Distrust the paperwork.** Check any plan, `status.yml`, `CLAUDE.md` claim or `docs/` page against the code and `git log --oneline -- <path>` before working from it. Trackers rot in both directions. Say plainly which claims you falsified and fix the doc in the same change.
3. **Explore** read-only, in parallel when the surface is broad → a ranked worklist in PR-sized batches. Broad or risky → write it down with `/planx` first.
4. **Branch.** `git fetch origin && git status --short` (expect clean), then `git checkout -b <type>/<slug>`. Never build on `main`.
5. **Build test-first, primitive-first.** Failing spec, then the code. One reusable primitive with its first real caller; no abstraction before a consumer. New object type → skill `add-schema-object`.
6. **Prove it** — skill `verify-change`:
   - while iterating: `bin/check files <paths you edited>` or `bin/check fast`
   - once, before the PR: `bin/check` (rubocop + full rspec, the same as CI)
   - UI change in `app/` → `bin/dev --detach`, open `http://127.0.0.1:3000/better_structure_sql/schema_versions`, then `bin/stop`
   - exit 75 → the environment is missing, not the change: `bin/setup`, then rerun
   - red is not a pull request: fix the cause, never silence a cop or skip a spec.
   Then a fresh-context pass over `git diff main...`: delete debug output, specs of framework behaviour, checks for impossible cases; rerun the gate.
7. **Changelog.** User-visible change → one line under `## [Unreleased]` in `CHANGELOG.md`. Never bump `lib/better_structure_sql/version.rb` here.
8. **One PR in flight.** `git add <named paths>` (never `-A`), read `git status --short`, commit, `git push -u origin HEAD`, `gh pr create`. Watch it: `gh pr checks --watch`. Red CI → `gh run view --log-failed`, fix, push. Merge with `gh pr merge --squash --delete-branch`, then `git checkout main && git pull` and confirm `gh run list --branch main --limit 1` is green before starting anything else.
9. **Close.** Re-check the original symptom on `main`. Update the plan's `status.yml` (`evidence`, `works`, `status`), close issues the PR did not auto-close.

## Fan-out — one checkout, no worktrees

Hive only for a broad search or several path-disjoint slices. One file, one fix → do it yourself.

**Never use git worktrees** — no `isolation: worktree`, no `git worktree add`. Work lands where nobody is looking, and every tree needs its own bundle and its own database. One checkout; the file set is the only lock.

Restate these to every agent you spawn:

- **Exclusive file set**, named in the brief, plus the paths every other live agent holds. Need a file you do not own → stop and report the collision.
- **No git at all** — no add, commit, branch, checkout, stash, reset. The coordinator owns git and touches it only once every agent has returned.
- **Checks narrowed to your own files:** `bin/check files <paths>`. Never bare `bin/check`, never `bin/check fast` (it diffs the whole shared tree).
- **Database specs need a private database:** `BSS_TEST_DB=bss_<slice> bin/check files <paths>` — created on first use. The suite truncates tables, so two agents on one database corrupt each other.
- **Evidence first, diagnosis second.** A hypothesis in a brief is labelled unverified; the agent may drop any premise the code contradicts and must say so.
- **Never "ask me".** A subagent cannot reach the user: decide and flag the assumption, or stop and report with evidence.

The coordinator runs the repo-wide `bin/check` once, at the end, and dispatches every slice it names. Shared files (`lib/better_structure_sql.rb`, `dumper.rb`, `configuration.rb`, `CHANGELOG.md`, `README.md`) are a choke point: one owner, or edited last by the coordinator.

**Cap a PR at ~110 changed files.** Past that, split along the slice boundaries even if one PR was asked for, and say why. Merge queue depth is 1 in every mode.

## Hard rules

- Never `--force` push to `main`, never `git stash`, never a git worktree.
- Never `gem push`, never create or push a tag, never `rake release` — CI publishes when a version bump merges (`/release`, `RELEASE.md`).
- Dump output is the product: a change to generated SQL needs a spec asserting the exact text, and identical output on a second run.

## Output
```
Shipped:   <what changed, one line per slice>
Gate:      bin/check <green|red>   CI on main <green|red|not checked>
PR:        #NNN <merged|open>
Deferred:  <n> — <what, and why not now>        [never omit this line]
Falsified: <plan/doc claims that were wrong, now corrected>
```
