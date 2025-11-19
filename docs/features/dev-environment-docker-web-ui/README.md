# Development Environment with Docker and Web UI

## Overview

Complete Docker-based development environment with PostgreSQL database, Rails integration app, and mountable Rails Engine providing web UI for browsing and viewing stored schema versions.

## Use Cases

### Developer Onboarding
- Pull repository, run `docker compose up`
- Access integration app at localhost:3000
- Browse stored schema versions via web UI
- Download schemas for comparison or restoration

### Schema Version Management
- View list of all stored schema versions
- See formatted schema with syntax highlighting
- Download raw schema as text file
- Compare versions side-by-side

### Engine Integration Testing
- Mount engine in any Rails application
- Configure authentication/authorization (Devise, Pundit, etc)
- Customize route prefix (default: `/better_structure_sql`)
- Test with different database configurations

### Multi-Database Support (Future)
- Load custom database.yml configurations
- Test schema dumping across database types
- Validate engine compatibility

## Configuration

### Docker Environment

**Services**:
- `postgres`: PostgreSQL database with persistent volume
- `web`: Rails integration app on port 3000

**Volumes**:
- `postgres_data`: Persistent PostgreSQL data
- `.:/app`: Mount gem source for live development

**Networking**:
- Internal network (postgres not exposed externally)
- Port 3000 exposed for web access

### Integration App

**Custom Configuration Support**:
- `config/database.yml`: Custom database connections
- `config/initializers/better_structure_sql.rb`: Dump format (sql/rb), versioning settings
- Environment-specific overrides

**Engine Mounting**:
- Routes mounted at `/better_structure_sql`
- Authentication via Devise or custom strategy
- Authorization via Pundit, CanCanCan, or custom

### Web Engine

**Dependencies**:
- Bootstrap 5 (via CDN)
- Bootstrap Icons (via CDN)
- No asset compilation required

**Routes**:
- `GET /better_structure_sql/schema_versions` - List all versions
- `GET /better_structure_sql/schema_versions/:id` - Show formatted version
- `GET /better_structure_sql/schema_versions/:id/raw` - Download raw text

**Authentication**:
- Configurable authentication method
- Example: `authenticate_admin!` before_action
- Documented patterns for Devise, custom auth

## Examples

### Starting Development Environment

```bash
# Start all services
docker compose up

# Run in background
docker compose up -d

# View logs
docker compose logs -f web

# Access Rails console
docker compose exec web rails console

# Run tests
docker compose exec web bundle exec rspec
```

### Accessing Web UI

```
# List versions
http://localhost:3000/better_structure_sql/schema_versions

# View specific version (formatted)
http://localhost:3000/better_structure_sql/schema_versions/1

# Download raw schema
http://localhost:3000/better_structure_sql/schema_versions/1/raw
```

### Custom Configuration

```ruby
# config/initializers/better_structure_sql.rb
BetterStructureSql.configure do |config|
  config.output_path = "db/structure.sql"  # or schema.rb
  config.enable_schema_versions = true
  config.schema_versions_limit = 10
end
```

### Authentication Setup

```ruby
# config/routes.rb (host application)

# Example 1: Devise authentication
authenticate :user, ->(user) { user.admin? } do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end

# Example 2: Simple Devise authentication (any logged-in user)
authenticate :user do
  mount BetterStructureSql::Engine, at: "/better_structure_sql"
end

# Example 3: Custom authentication constraint
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

# Example 4: No authentication (development only!)
mount BetterStructureSql::Engine, at: "/better_structure_sql"
```

## Architecture Components

**Docker Infrastructure**:
- Dockerfile for Rails app
- docker-compose.yml orchestration
- Database initialization scripts
- Volume management

**Rails Engine** (`better_structure_sql-web`):
- Controller: schema_versions CRUD
- Views: Bootstrap 5 layouts
- Routes: RESTful resource
- Models: BetterStructureSql::SchemaVersion

**Integration App** (`test/dummy` or `integration`):
- Mounts engine
- Sample authentication
- Custom configurations
- Seed data for testing

## Dependencies

- Docker Engine 20.10+
- Docker Compose 2.0+
- PostgreSQL 13+ (via Docker image)
- Ruby 3.0+ (in Docker container)
- Rails 7.0+ (in Docker container)

## Success Criteria

- [ ] Single command starts full environment
- [ ] Web UI accessible without asset compilation
- [ ] Schema versions browsable and downloadable
- [ ] Authentication configurable and documented
- [ ] Custom database.yml and initializer support
- [ ] Live code reloading during development
- [ ] PostgreSQL data persists across restarts
- [ ] Tests pass in Docker environment
