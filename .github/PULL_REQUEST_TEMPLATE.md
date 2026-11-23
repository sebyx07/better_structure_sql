## What and why

<!-- One or two sentences. Link issues: Fixes #123 -->

## Changes

-

## Checklist

- [ ] `bin/check` passes (tests and linters, the same gate CI runs)
- [ ] Changed behaviour has specs; an adapter change has specs for that adapter
- [ ] Dump output stays deterministic: every introspected list is ordered
- [ ] Generated SQL loads back into the database that produced it
- [ ] Identifiers and values reach introspection queries through `connection.quote` / `quote_table_name`
- [ ] `CHANGELOG.md` `## [Unreleased]` updated for user-visible changes
- [ ] `README.md`, `docs/` and `llms.txt` updated if options, tasks or output changed

Keep the pull request a draft until it is ready: the maintainer agent merges a ready pull request once CI is green.
