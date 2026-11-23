# app/ — the schema versions engine

Mountable engine (`lib/better_structure_sql/engine.rb`, routes in `config/routes.rb`): `schema_versions` index, show, `raw`, `download`. It displays the host application's full database schema, so treat every change as security-relevant.

- **Fails closed.** `ApplicationController#authenticate_access!` is a `before_action` on every controller. Outside `development` and `test` it answers 403 until the host calls `Engine.authenticate_with { |controller| ... }` or `Engine.authentication_handled_by_routes!`. Never add an action, controller or environment that bypasses it; never widen `LOCAL_ENVIRONMENTS`.
- **Stored content is untrusted text.** Views escape it: no `raw`, no `html_safe`, no `<%==` on schema content. `raw` and `download` respond `text/plain` or as an attachment, never as HTML.
- **No caching of schemas.** Keep the `no_store` `before_action`.
- **Large columns stay out of lists.** `index` and metadata lookups select `METADATA_COLUMNS` only; `content` and `zip_archive` are read only by the action that sends them, and large content is streamed in chunks.
- No asset pipeline: Bootstrap and icons come from a CDN in `app/views/layouts/better_structure_sql/application.html.erb`.
- Specs: `spec/controllers/better_structure_sql/`, `spec/requests/better_structure_sql/engine_spec.rb`, `spec/routing/`, `spec/helpers/`. A new action needs the denied-access case as well as the allowed one. Specs that register access control call `Engine.reset_authentication!` afterwards.
- See it running: `bin/dev`, then http://127.0.0.1:3000/better_structure_sql/schema_versions.
- Docs to update with behaviour changes: `docs/features/web-ui.md`.
