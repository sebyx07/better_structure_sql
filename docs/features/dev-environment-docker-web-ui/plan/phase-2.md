# Phase 2: Rails Engine with Web UI

## Objective

Create mountable Rails Engine providing web interface for browsing and downloading schema versions using Bootstrap 5 from CDN (no asset compilation required).

## Deliverables

### Engine Structure
- `lib/better_structure_sql/engine.rb` - Rails::Engine configuration
- `app/controllers/better_structure_sql/application_controller.rb` - Base controller
- `app/controllers/better_structure_sql/schema_versions_controller.rb` - CRUD controller
- `app/views/better_structure_sql/layouts/application.html.erb` - Bootstrap layout
- `app/views/better_structure_sql/schema_versions/index.html.erb` - List view
- `app/views/better_structure_sql/schema_versions/show.html.erb` - Detail view
- `config/routes.rb` - Engine routes

### ApplicationController
- Base controller for engine namespace
- Authentication hook method (`authenticate_admin!`)
- Default implementation (override in host app)
- Layout specification
- Error handling

### SchemaVersionsController
- `index` action - List all versions (paginated)
- `show` action - Display single version (formatted)
- `raw` action - Download as text file
- Ordering by created_at DESC
- Format handling (HTML, text)

### Views with Bootstrap 5 CDN

**Layout (`layouts/application.html.erb`)**
- Bootstrap 5.3 CSS from CDN
- Bootstrap Icons from CDN
- Bootstrap JS bundle from CDN
- Navigation header
- Flash message display
- Responsive viewport meta tag

**Index View**
- Table with columns: ID, Format, PG Version, Created At, Actions
- Bootstrap table styling (table-striped, table-hover)
- Action buttons: View, Download Raw
- Pagination controls (will_paginate or kaminari)
- Empty state message
- Create button (optional, for manual versioning)

**Show View**
- Metadata section (ID, format, PG version, created at)
- Schema content in code block with syntax highlighting
- Download raw button
- Back to list link
- Copy to clipboard button
- Bootstrap card layout

### Routes Configuration
- Namespace: `better_structure_sql`
- Resource: `schema_versions` (only: [:index, :show])
- Custom route: `GET schema_versions/:id/raw`
- Root redirect to index

### Engine Configuration
- Isolated namespace: `BetterStructureSql`
- Auto-load paths for app directories
- View path configuration
- No asset pipeline dependencies
- Helper methods available to views

## Testing Requirements

### Controller Tests
- [ ] Index renders successfully
- [ ] Index displays all versions ordered by date
- [ ] Show renders specific version
- [ ] Show returns 404 for missing version
- [ ] Raw returns text/plain content-type
- [ ] Raw includes content-disposition header
- [ ] Authentication hook called before actions
- [ ] Pagination works with many versions

### View Tests
- [ ] Layout includes Bootstrap CSS from CDN
- [ ] Layout includes Bootstrap Icons from CDN
- [ ] Index table displays version data
- [ ] Index shows empty state when no versions
- [ ] Show displays formatted schema content
- [ ] Show renders metadata correctly
- [ ] All links navigate correctly
- [ ] Responsive design works on mobile

### Integration Tests
- [ ] Engine mounts in host app successfully
- [ ] Routes accessible at /better_structure_sql
- [ ] Full user flow: index -> show -> raw
- [ ] Authentication respected when configured
- [ ] No asset compilation required
- [ ] Works without JavaScript enabled (progressive enhancement)

### Engine Mounting Tests
- [ ] Mount at default path (/better_structure_sql)
- [ ] Mount at custom path (/admin/schemas)
- [ ] Multiple mounts possible
- [ ] Routes helper methods work (schema_versions_path)

## Success Criteria

1. Engine mounts successfully in integration app
2. Web UI accessible at `/better_structure_sql/schema_versions`
3. Bootstrap 5 styling renders from CDN (no asset compilation)
4. Schema versions list displays with proper formatting
5. Individual version viewable with formatted SQL/Ruby
6. Raw text download works with proper content-type
7. Authentication hook can be customized in host app
8. Responsive design works on desktop and mobile
9. All tests pass in Docker environment
10. Documentation covers authentication setup examples

## Dependencies

### External Dependencies
- Rails 7.0+ (engine framework)
- Bootstrap 5.3 (via CDN)
- Bootstrap Icons (via CDN)

### Internal Dependencies
- Phase 1 completed (Docker environment running)
- BetterStructureSql::SchemaVersion model (already exists)
- schema_versions table in database

### Gem Dependencies (Optional)
- `will_paginate` or `kaminari` (pagination)
- `syntax_highlighter` (optional for code highlighting)

## Implementation Steps

1. Create engine directory structure
2. Define Engine class in `lib/better_structure_sql/engine.rb`
3. Create ApplicationController with auth hook
4. Create SchemaVersionsController with actions
5. Create layout with Bootstrap CDN links
6. Create index view with table and pagination
7. Create show view with formatted content
8. Add raw action for text download
9. Configure routes in engine
10. Mount engine in integration app
11. Add controller tests
12. Add view tests
13. Add integration tests
14. Document authentication setup patterns

## Validation

### Manual Testing
```bash
# Start environment
docker compose up

# Navigate to engine
open http://localhost:3000/better_structure_sql/schema_versions

# Test index page
- Verify Bootstrap styling loaded
- Check table displays versions
- Test pagination if many versions

# Test show page
- Click version to view
- Verify syntax highlighting
- Check metadata display

# Test raw download
- Click "Download Raw" button
- Verify text file downloads
- Check content matches database
```

### Authentication Testing
```ruby
# In integration app controller
before_action :authenticate_admin!

def authenticate_admin!
  head :unauthorized unless session[:admin]
end

# Test unauthorized access
curl -I http://localhost:3000/better_structure_sql/schema_versions
# Should return 401

# Test authorized access
# Set session[:admin] = true
# Should return 200
```

### Automated Testing
```bash
# Run engine controller tests
docker compose exec web bundle exec rspec spec/controllers/better_structure_sql

# Run engine view tests
docker compose exec web bundle exec rspec spec/views/better_structure_sql

# Run integration tests
docker compose exec web bundle exec rspec spec/requests/better_structure_sql
```

## Authentication Documentation

Document these patterns in README:

### Devise Integration (Route Constraints)
```ruby
# config/routes.rb

# Admin users only
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end

# Any authenticated user
authenticate :user do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end
```

### Custom Constraint
```ruby
# config/routes.rb

class AdminConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find_by(id: request.session[:user_id])
    user&.admin?
  end
end

constraints AdminConstraint.new do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end
```

### Alternative: Controller-Level Authentication
```ruby
# If route constraints don't work for your auth system
BetterStructureSql::ApplicationController.class_eval do
  before_action :check_api_key

  private

  def check_api_key
    head :unauthorized unless valid_api_key?
  end

  def valid_api_key?
    request.headers['X-API-Key'] == ENV['ADMIN_API_KEY']
  end
end
```

## Rollback Plan

If phase fails:
- Remove engine code
- Keep Phase 1 Docker environment
- Continue with command-line interface only
- Engine development can be separate gem
