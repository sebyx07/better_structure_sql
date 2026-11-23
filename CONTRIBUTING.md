# Contributing

Bug reports and pull requests are welcome at https://github.com/sebyx07/better_structure_sql. AI-assisted contributions are welcome too; the same checks apply.

## Setup

Requirements: the Ruby in `.ruby-version` (mise or rbenv), and either Docker or a PostgreSQL you point `DATABASE_URL` at.

```bash
bin/setup                  # Ruby, gems, PostgreSQL, test database; safe to rerun
bin/check                  # the gate: rubocop + full rspec, the same commands CI runs
bin/check fast             # inner loop: rubocop on changed files + specs that need no database
bin/check files <path>...  # only the named files
bin/dev                    # integration app with the web UI on http://127.0.0.1:3000
bin/stop                   # stop what bin/dev and bin/setup started
```

Exit code 75 from any script means the environment is missing something, not that a check failed: run `bin/setup`. Each script documents itself in its header comment.

## Where things are

| Path | What |
|---|---|
| `lib/better_structure_sql/adapters/` | One adapter per database: introspection queries and capability flags |
| `lib/better_structure_sql/generators/` | One SQL generator per object type |
| `lib/better_structure_sql/dumper.rb` | Orchestration and section order |
| `lib/better_structure_sql/file_writer.rb`, `schema_loader.rb` | Multi-file write and load |
| `lib/better_structure_sql/schema_versions.rb`, `schema_version.rb` | Stored versions |
| `app/`, `config/routes.rb`, `lib/better_structure_sql/engine.rb` | Web UI engine |
| `lib/tasks/better_structure_sql.rake` | Rake tasks |
| `spec/` | RSpec suite |
| `integration/`, `integration_mysql/`, `integration_sqlite/` | Rails apps per database; not packaged in the gem |
| `site/` | Docs site (React), deployed to GitHub Pages |

Rules for agents and the full code map: [CLAUDE.md](CLAUDE.md). Internals: [docs/architecture.md](docs/architecture.md). Tests: [docs/testing.md](docs/testing.md).

## Pull requests

1. Branch from `main`; keep the pull request focused on one change.
2. Add or adjust specs for every behaviour change. An adapter change needs specs for that adapter.
3. Keep dumps deterministic: order every introspected list, no timestamps or server versions in output.
4. Generated SQL must load back into the database that produced it.
5. Pass identifiers and values to introspection queries through `connection.quote` / `quote_table_name`, never raw interpolation.
6. Add a line under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
7. Update [README.md](README.md), `docs/` and [llms.txt](llms.txt) when options, tasks or output change.
8. Run `bin/check` before marking the pull request ready.

The pull request template carries this checklist.

## Style

RuboCop (`.rubocop.yml`) with rubocop-rails, rubocop-rspec and rubocop-performance. Public methods carry YARD comments. Follow the patterns in the file you are editing.

## Reporting bugs

Use the bug report form. The maintainer agent needs steps to reproduce, the expected result, the actual result, the gem version and the environment (database and its version, Ruby, Rails); a report missing them is asked for them before anything else happens.

Security problems go to [SECURITY.md](SECURITY.md), never to a public issue.

## How pull requests get merged

This repo is maintained by [developerz.ai](https://developerz.ai). Its agent reviews every pull request, may request changes, and merges every pull request (contributors, members, bots) once you mark it ready for review and CI is green; keep it a draft until then. The policy is in [`.dz/maintainer/maintainer.yml`](.dz/maintainer/maintainer.yml). Commit with an email linked to your GitHub account.

Changes to CI, release or publishing automation (`.github/`, `bin/`, the gemspec, `BetterStructureSql::VERSION`) are made by the owner only. Breaking changes are decided by the owner.

Releases are cut by merging a version bump: see [RELEASE.md](RELEASE.md).

## Conduct and license

Participation is covered by the [Code of Conduct](CODE_OF_CONDUCT.md). By contributing you agree your contributions are licensed under the [MIT License](LICENSE).
