# Phase 1: Docker Environment Setup

## Objective

Establish Docker-based development environment with PostgreSQL database and Rails integration app, enabling single-command startup with persistent data storage.

## Deliverables

### Dockerfile
- Ruby 3.2-alpine base image
- System dependencies (postgresql-dev, build-base, nodejs)
- Gem installation from local source
- Rails app setup
- Exposed port 3000
- Working directory configuration

### docker-compose.yml
- PostgreSQL service (postgres:15-alpine)
- Web service (Rails app)
- Internal network (no external postgres port)
- Volume for PostgreSQL persistence
- Volume mount for live gem development
- Environment variables for database connection
- Health checks for service readiness
- Dependency ordering (web depends on postgres)

### Database Configuration
- `integration/config/database.yml`
- Development environment using postgres service
- Test environment configuration
- Environment variable substitution
- Connection pooling settings

### Integration App Structure
- New Rails app in `integration/` directory
- Mounted gem as local dependency
- Database migration for schema_versions table
- Seed data with sample schema versions
- Basic routes and home page

### Documentation
- README with startup instructions
- Environment variable reference
- Common Docker commands
- Troubleshooting guide

## Testing Requirements

### Docker Build Tests
- [x] Dockerfile builds without errors
- [x] All dependencies install successfully
- [x] Image size reasonable (~728MB Alpine with full dev environment)
- [x] Build cache layers effective

### Docker Compose Tests
- [x] `docker compose up` starts all services
- [x] PostgreSQL service becomes healthy
- [x] Web service connects to database
- [x] Port 3000 accessible from host
- [x] Volume persists data across restarts
- [x] Live code changes reflect without rebuild

### Integration App Tests
- [x] Rails app loads successfully
- [x] Database connection established
- [x] Migrations run automatically
- [x] Seed data creates sample users and posts
- [x] Home page accessible at localhost:3000
- [x] Rails console works via docker exec

### Persistence Tests
- [x] Stop and restart containers
- [x] Database data survives restart
- [x] Users and posts tables intact
- [x] Seed data persists

## Success Criteria

1. Single command starts environment: `docker compose up`
2. Web app accessible at `http://localhost:3000` within 30 seconds
3. PostgreSQL data persists across container restarts
4. Code changes in mounted volume reflect without image rebuild
5. Rails console accessible: `docker compose exec web rails console`
6. Tests pass in Docker: `docker compose exec web bundle exec rspec`
7. Clean shutdown: `docker compose down` stops all services
8. Database volume cleanup: `docker compose down -v` removes data

## Dependencies

### External Dependencies
- Docker Engine 20.10+
- Docker Compose 2.0+
- Host port 3000 available

### Internal Dependencies
- Existing gem codebase
- Schema versions table migration (already exists)
- BetterStructureSql::SchemaVersion model (already exists)

## Implementation Steps

1. Create `integration/` directory structure
2. Generate new Rails app with postgresql adapter
3. Create Dockerfile with optimized layers
4. Create docker-compose.yml with services and volumes
5. Configure database.yml for Docker environment
6. Add gem as local dependency in Gemfile
7. Copy schema_versions migration to integration app
8. Create seed data with sample versions
9. Add .dockerignore for build optimization
10. Test build and startup process
11. Document commands and troubleshooting

## Code Quality

### Rubocop
- [x] All code passes Rubocop linting with no offenses (80 files inspected)
- [x] Auto-corrected 190 offenses (frozen string literals, string quotes, spacing)
- [x] Integration app follows Ruby style guide

## Validation

### Manual Testing
```bash
# Clean start
docker compose down -v
docker compose build
docker compose up

# Verify services
docker compose ps
curl http://localhost:3000

# Check database
docker compose exec web rails dbconsole
SELECT COUNT(*) FROM better_structure_sql_schema_versions;

# Test persistence
docker compose restart postgres
docker compose exec web rails console
# Verify data still exists
```

### Automated Testing
```bash
# Run test suite in Docker
docker compose exec web bundle exec rspec

# Run rubocop
docker compose exec web bundle exec rubocop
```

## Rollback Plan

If phase fails:
- Remove `integration/` directory
- Remove Docker files
- Continue development with local PostgreSQL
- Engine development continues independently
