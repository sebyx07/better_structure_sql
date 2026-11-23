# Security Policy

## Supported versions

Only the latest release on [RubyGems](https://rubygems.org/gems/better_structure_sql) gets security fixes. Fixes land on `main` and ship in the next release.

## Reporting a vulnerability

**Report privately by email to sebyx07.pro@gmail.com. Do not open a public issue or pull request:** both are public, and an AI agent triages them in the open.

Include:

- what is affected: the gem version, the database and its version, the Rails version
- steps to reproduce, ideally a small schema or script
- the impact as you understand it

There is no fixed response time. Reports are read and fixed as maintainer time allows, and you are credited in the changelog unless you ask not to be.

## In scope

- Access to the schema versions web UI (`app/`, `BetterStructureSql::Engine`) without the host application's access check passing
- Stored schema content rendered unescaped in the web UI
- SQL injection through introspection queries (`lib/better_structure_sql/adapters/`)
- ZIP handling: path traversal on extraction, or archives that bypass the file-count and size limits (`lib/better_structure_sql/zip_generator.rb`)
- Anything in the published gem or its release pipeline that runs code a user did not ask for

## Out of scope

- The integration apps (`integration/`, `integration_mysql/`, `integration_sqlite/`) and the docs site (`site/`): they are not packaged in the gem
- An engine mounted with an access check that allows everyone
- `db:schema:load_better` and `db:schema:restore` executing the SQL they are given: loading a schema is their purpose, so only load files and versions you trust
- Schema contents visible to a user your application authorised
