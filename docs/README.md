# Docs

The index of this directory. Add a line when you add a page. The agent brain is the root
[`CLAUDE.md`](../CLAUDE.md); the commands are `bin/setup`, `bin/dev`, `bin/check` and `bin/stop`.

## Intent

| Page | What it holds |
|---|---|
| [`docs/idea/direction.md`](idea/direction.md) | What the product is for, what "better" means here, what is out of bounds (a draft for the owner) |
| [`docs/idea/overview.md`](idea/overview.md) | What better_structure_sql is and who uses it |
| [`docs/idea/principles.md`](idea/principles.md) | Why the invariants exist |
| [`docs/idea/stack.md`](idea/stack.md) | Languages, test, lint and build tools |
| [`docs/idea/data-model.md`](idea/data-model.md) | The schema versions table and the dump layout |
| [`docs/idea/deployment.md`](idea/deployment.md) | How the gem and the docs site ship |
| [`docs/standards/README.md`](standards/README.md) | The rules a change follows, and the check that enforces each |

## Guides for users

| Page | What it holds |
|---|---|
| [`docs/installation.md`](installation.md) | Adding the gem, the initializer and the migration |
| [`docs/configuration.md`](configuration.md) | Every option and its default |
| [`docs/usage.md`](usage.md) | Rake tasks and the Ruby API |
| [`docs/schema_versions.md`](schema_versions.md) | Storing, listing, restoring and pruning schema versions |
| [`docs/features/multi-file-output.md`](features/multi-file-output.md) | The directory layout and chunking |
| [`docs/features/multi-database.md`](features/multi-database.md) | PostgreSQL, MySQL and SQLite support |
| [`docs/features/web-ui.md`](features/web-ui.md) | Mounting the engine and declaring access control |
| [`docs/migration-guides/from-schema-rb-to-structure-sql.md`](migration-guides/from-schema-rb-to-structure-sql.md) | Moving an app from the Ruby schema file |

## Internals

| Page | What it holds |
|---|---|
| [`docs/architecture.md`](architecture.md) | How a dump is produced, and which file owns each step |
| [`docs/testing.md`](testing.md) | Running and writing the specs |

Also: [`README.md`](../README.md), [`llms.txt`](../llms.txt) and the
[docs site](https://sebyx07.github.io/better_structure_sql/) for users;
[`CONTRIBUTING.md`](../CONTRIBUTING.md) and [`RELEASE.md`](../RELEASE.md) for contributors.
