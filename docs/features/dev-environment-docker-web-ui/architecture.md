# Architecture: Development Environment and Web UI

## System Components

### Docker Infrastructure Layer

**PostgreSQL Service**
- Responsibility: Database server for integration app
- Image: postgres:15-alpine
- Volume: `postgres_data` for persistence
- Network: Internal only (no external ports)
- Configuration: Environment variables for credentials

**Rails Web Service**
- Responsibility: Run integration app with mounted engine
- Build: Custom Dockerfile from gem root
- Port: 3000 exposed to host
- Volumes: Gem source mounted for live development
- Dependencies: PostgreSQL service availability

**Docker Compose Orchestration**
- Responsibility: Service coordination and networking
- Networks: Single internal network
- Health checks: PostgreSQL readiness
- Environment: Development-optimized settings

### Rails Engine Layer (`better_structure_sql-web`)

**Engine Structure**
```
lib/better_structure_sql/
  engine.rb              # Rails::Engine configuration
app/
  controllers/better_structure_sql/
    application_controller.rb
    schema_versions_controller.rb
  views/better_structure_sql/
    layouts/
      application.html.erb  # Bootstrap 5 layout
    schema_versions/
      index.html.erb        # List view with table
      show.html.erb         # Formatted schema display
  models/better_structure_sql/
    schema_version.rb       # Already exists in gem
config/
  routes.rb               # Engine routes
```

**ApplicationController**
- Responsibility: Base controller with authentication hook
- Methods: `authenticate_admin!` (override in host app)
- Layout: Bootstrap 5 from CDN
- Error handling: Standard Rails responses

**SchemaVersionsController**
- Responsibility: CRUD operations for schema versions
- Actions: `index`, `show`, `raw`
- Format support: HTML, text (for raw)
- Ordering: Most recent first (created_at DESC)

**Views**
- Responsibility: Render schema versions with Bootstrap 5
- Layout: CDN-loaded Bootstrap 5.3, Bootstrap Icons
- Index: Table with pagination, timestamps, format types
- Show: Code block with syntax highlighting, metadata
- Raw: Plain text response (Content-Type: text/plain)

**Routes**
- Responsibility: RESTful resource for schema versions
- Namespace: `/better_structure_sql`
- Resources: `schema_versions` (only: index, show)
- Custom: `schema_versions/:id/raw` (text download)

### Integration App Layer

**Application Structure**
```
integration/              # or test/dummy
  app/
    controllers/
      application_controller.rb
    models/
      user.rb             # Optional for Devise
  config/
    database.yml          # Custom DB configurations
    routes.rb             # Mount engine
    initializers/
      better_structure_sql.rb  # Gem configuration
      devise.rb           # Optional authentication
  db/
    migrate/              # Schema versions table migration
    seeds.rb              # Sample data
  Dockerfile
  docker-compose.yml
```

**Responsibilities**
- Mount engine at configurable path
- Provide authentication implementation
- Load custom database configurations
- Seed sample schema versions
- Serve as development test bed

**Configuration Management**
- Database: Custom database.yml per environment
- Gem: Initializer for output format, versioning settings
- Engine: Authentication and authorization setup
- Routes: Configurable mount point

### Database Schema Layer

**Schema Versions Table**
```sql
better_structure_sql_schema_versions (
  id: bigint primary key,
  content: text not null,
  pg_version: varchar,
  format_type: varchar,
  created_at: timestamp not null,
  INDEX idx_created_at DESC
)
```

**Responsibilities**
- Store schema snapshots (structure.sql or schema.rb)
- Track PostgreSQL version compatibility
- Support retention limit cleanup
- Efficient querying by recency

## Component Interactions

### Development Workflow
1. Developer runs `docker compose up`
2. Docker builds Rails image from Dockerfile
3. PostgreSQL starts with volume mount
4. Rails app waits for PostgreSQL readiness
5. Database migration creates schema_versions table
6. Seed data populates sample versions
7. Rails server starts on port 3000
8. Engine routes available at `/better_structure_sql`

### Schema Version Viewing Flow
1. User navigates to `/better_structure_sql/schema_versions`
2. Engine ApplicationController checks authentication
3. SchemaVersionsController#index queries recent versions
4. View renders Bootstrap table with version metadata
5. User clicks version to view details
6. Controller#show loads specific version
7. View renders formatted schema with syntax highlighting
8. User can click "Raw" link for text download
9. Controller#raw returns content as text/plain

### Configuration Loading Flow
1. Rails initializers load in order
2. `config/database.yml` establishes DB connection
3. `initializers/better_structure_sql.rb` configures gem
4. Engine initializer sets authentication callback
5. Routes mount engine at specified path
6. Application ready for requests

## Dependencies

### Engine Dependencies (Gemspec)
- `rails >= 7.0` (Engine framework)
- `better_structure_sql` (Core gem, parent)
- No asset dependencies (Bootstrap via CDN)

### Integration App Dependencies
- `better_structure_sql` (gem under development)
- `better_structure_sql-web` (engine, local path)
- `pg` (PostgreSQL adapter)
- `devise` (optional, for authentication example)
- `pundit` or `cancancan` (optional, for authorization)

### Docker Dependencies
- Base image: `ruby:3.2-alpine`
- PostgreSQL image: `postgres:15-alpine`
- System packages: build-base, postgresql-dev, nodejs

## Extension Points

### Authentication Customization
```ruby
# Primary approach: Route constraints in config/routes.rb
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end

# Alternative: Custom constraint class
class AdminConstraint
  def matches?(request)
    # Custom logic
  end
end

constraints AdminConstraint.new do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end
```

### Route Customization
```ruby
# Mount at custom path
authenticate :user do
  mount BetterStructureSql::Engine, at: "/admin/schemas"
end
```

### View Customization
- Override engine views in host app
- Path: `app/views/better_structure_sql/...`
- Inherits layout from engine or use host layout

### Configuration Customization
- Database: Multiple database support via database.yml
- Output: Toggle between structure.sql and schema.rb
- Retention: Configure version limit per environment

## Security Considerations

### Authentication Required
- No public access to schema versions
- Configurable authentication method
- Examples provided for common patterns
- Clear documentation for custom implementation

### Authorization Patterns
- Document admin-only access example
- Show integration with Pundit/CanCanCan
- Provide custom policy examples

### Content Security
- Schema content is structure only (no data)
- Raw download includes Content-Disposition header
- No user-provided content execution
- SQL displayed as text, not executed

## Performance Characteristics

### Docker Startup
- First build: 2-3 minutes (image creation)
- Subsequent starts: 10-20 seconds (cached layers)
- Volume initialization: One-time on first run

### Web UI Performance
- Index page: Query with LIMIT and ORDER BY (fast)
- Show page: Single row lookup by ID (indexed)
- Raw download: Stream large content (no memory loading)
- Pagination: Offset-based for large version lists

### Development Workflow
- Live reload: Code changes reflect without rebuild
- Volume mount: No image rebuild for gem changes
- Database persistence: Data survives container restarts
- Test suite: Runs in isolated Docker environment
