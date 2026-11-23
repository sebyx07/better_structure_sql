# Web UI

A mountable Rails engine that lists stored [schema versions](../schema_versions.md), shows their content and offers downloads. It reads the `better_structure_sql_schema_versions` table and nothing else.

## Mount

```ruby
# config/routes.rb
mount BetterStructureSql::Engine, at: '/schema_versions'
```

| Route (relative to the mount point) | Action |
|---|---|
| `/` and `/schema_versions` | List, newest first, paginated with `?page=N` |
| `/schema_versions/:id` | Metadata and, for content up to the display limit, the schema text |
| `/schema_versions/:id/raw` | Schema text as a `text/plain` attachment |
| `/schema_versions/:id/download` | ZIP for a multi-file version with an archive, otherwise the schema file |

Mounted at `/schema_versions`, the list is at `/schema_versions` and a version at `/schema_versions/schema_versions/5`. Mount at `/better_structure_sql` if you prefer `/better_structure_sql/schema_versions/5`.

Size limits (inline display, streaming threshold, page size) are constants at the top of [`schema_versions_controller.rb`](../../app/controllers/better_structure_sql/schema_versions_controller.rb). Larger content is streamed in chunks instead of loaded whole.

## Access control

The UI exposes the full database schema, so it **fails closed**. In development and test it is open. In every other environment each request gets `403 Forbidden` until the application declares one of these in `config/initializers/better_structure_sql.rb`:

**1. A check that runs in the engine**

```ruby
BetterStructureSql::Engine.authenticate_with do |controller|
  controller.request.env['warden']&.user&.admin?
end
```

The block receives the controller and runs in every environment, development and test included. A truthy return allows the request; a falsy return answers `403 Forbidden`, unless the block already rendered or redirected.

**2. The routes already restrict access**

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql::Engine.authentication_handled_by_routes!

# config/routes.rb: Devise
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end

# config/routes.rb: a constraint class
class AdminConstraint
  def matches?(request)
    request.env['warden']&.user&.admin?
  end
end

constraints AdminConstraint.new do
  mount BetterStructureSql::Engine, at: '/schema_versions'
end
```

`authentication_handled_by_routes!` only tells the engine not to block; the route constraint is what protects the UI. Declaring it without a constraint leaves the UI public.

**3. Override the hook**

```ruby
# config/initializers/better_structure_sql.rb
Rails.application.config.to_prepare do
  BetterStructureSql::ApplicationController.class_eval do
    private

    def authenticate_access!
      head :unauthorized unless current_user&.admin?
    end
  end
end
```

Overriding `authenticate_access!` replaces the engine's check, so no other declaration is needed. Adding a separate `before_action` instead does not: the engine's own check still runs and still answers `403` unless you also call `authenticate_with` or `authentication_handled_by_routes!`.

`BetterStructureSql::ApplicationController` inherits from `ActionController::Base`, not from your `ApplicationController`: helpers such as `current_user` exist only if you include them.

## Behaviour

- Assets: Bootstrap and Bootstrap Icons from a CDN with subresource integrity. No asset pipeline setup. An application with a strict Content Security Policy must allow that CDN.
- Schema content is rendered escaped. Responses carry `Cache-Control: no-store`.
- The list and detail pages load metadata only; `content` and `zip_archive` are read by the actions that send them.
- A ZIP is validated (file count, uncompressed size) before it is sent.
- Ids are numeric; a missing id answers `404` with a plain-text body.
- Text downloads are `text/plain; charset=utf-8` attachments.

## Try it locally

```bash
bin/setup
bin/dev    # http://127.0.0.1:3000/better_structure_sql/schema_versions
```

`bin/dev` boots the PostgreSQL integration app in `integration/`, seeded with sample versions.
