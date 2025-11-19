# Docker Development Environment

This document describes the Docker-based development environment for BetterStructureSql.

## Overview

The Docker environment includes:
- **PostgreSQL 15** - Database service (internal network only)
- **Rails Integration App** - Web interface accessible on port 3000
- **Persistent Storage** - PostgreSQL data survives container restarts
- **Live Reload** - Gem source code mounted for development without rebuild

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Port 3000 available on host

## Quick Start

### Start the Environment

```bash
docker compose up
```

This single command will:
1. Build the Docker image (first time only)
2. Start PostgreSQL service
3. Wait for database to be ready
4. Run database migrations
5. Seed sample data
6. Start Rails server on port 3000

### Access the Application

Open your browser to [http://localhost:3000](http://localhost:3000)

The web interface shows:
- Current schema version statistics
- Environment information
- Link to browse stored schema versions

## Common Commands

### Build and Start Services

```bash
# Build images
docker compose build

# Start services in foreground
docker compose up

# Start services in background
docker compose up -d

# View logs
docker compose logs -f web
```

### Database Operations

```bash
# Run migrations
docker compose exec web rails db:migrate

# Seed database
docker compose exec web rails db:seed

# Reset database
docker compose exec web rails db:reset

# Open Rails console
docker compose exec web rails console

# Open database console
docker compose exec web rails dbconsole
```

### BetterStructureSql Operations

```bash
# Dump schema to structure.sql
docker compose exec web rails db:schema:dump

# Store current schema version
docker compose exec web rails db:schema:store

# List stored schema versions
docker compose exec web rails db:schema:versions

# Clean up old schema versions
docker compose exec web rails db:schema:cleanup
```

### Testing

```bash
# Run full test suite
docker compose exec web bundle exec rspec

# Run specific test file
docker compose exec web bundle exec rspec spec/models/user_spec.rb

# Run Rubocop
docker compose exec web bundle exec rubocop
```

### Stop and Clean Up

```bash
# Stop services (preserves data)
docker compose down

# Stop and remove volumes (deletes database data)
docker compose down -v

# Remove all containers, networks, and images
docker compose down --rmi all -v
```

## Environment Variables

The following environment variables are configured in `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_HOST` | `postgres` | PostgreSQL service hostname |
| `DATABASE_USERNAME` | `postgres` | Database username |
| `DATABASE_PASSWORD` | `postgres` | Database password |
| `DATABASE_NAME` | `better_structure_sql_development` | Database name |
| `RAILS_ENV` | `development` | Rails environment |

You can override these in a `.env` file or directly in `docker-compose.yml`.

## Volumes

### postgres_data
- **Purpose**: Persists PostgreSQL database files
- **Location**: Docker managed volume
- **Cleanup**: `docker compose down -v`

### bundle_cache
- **Purpose**: Caches Ruby gems to speed up builds
- **Location**: Docker managed volume
- **Cleanup**: `docker compose down -v`

### Source Code Mount
- **Source**: Current directory (`.`)
- **Target**: `/app` in container
- **Purpose**: Live code changes without rebuild
- **Note**: Changes to gem source reflect immediately in running container

## File Structure

```
better_structure_sql/
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Service orchestration
├── docker-entrypoint.sh    # Startup script
├── .dockerignore          # Files excluded from build
├── integration/           # Rails integration app
│   ├── app/
│   ├── config/
│   │   ├── database.yml   # Database configuration
│   │   └── initializers/
│   │       └── better_structure_sql.rb  # Gem configuration
│   ├── db/
│   │   ├── migrate/       # Database migrations
│   │   └── seeds.rb       # Sample data
│   ├── Gemfile            # Includes gem as local dependency
│   └── ...
└── lib/                   # Gem source code (mounted in container)
```

## Development Workflow

### Making Changes to the Gem

1. Edit gem source code in `lib/`
2. Changes are immediately available in the container (no rebuild needed)
3. Restart the Rails server if needed:
   ```bash
   docker compose restart web
   ```

### Adding Migrations

1. Generate migration in the integration app:
   ```bash
   docker compose exec web rails generate migration AddFieldToUsers
   ```
2. Edit the migration file in `integration/db/migrate/`
3. Run migrations:
   ```bash
   docker compose exec web rails db:migrate
   ```

### Testing Schema Dumping

1. Make schema changes via migrations
2. Dump schema:
   ```bash
   docker compose exec web rails db:schema:dump
   ```
3. View the generated file:
   ```bash
   docker compose exec web cat db/structure.sql
   ```

### Debugging

#### View Rails Logs
```bash
docker compose logs -f web
```

#### Inspect Database
```bash
docker compose exec web rails dbconsole
```

```sql
-- List all tables
\dt

-- Describe schema_versions table
\d better_structure_sql_schema_versions

-- Query schema versions
SELECT id, pg_version, format_type, created_at, LENGTH(content) as size
FROM better_structure_sql_schema_versions
ORDER BY created_at DESC;
```

#### Check Container Status
```bash
docker compose ps
docker compose exec web bundle exec rails runner "puts Rails.env"
```

## Troubleshooting

### Port 3000 Already in Use

```bash
# Find process using port 3000
lsof -i :3000

# Kill the process or change port in docker-compose.yml
ports:
  - "3001:3000"
```

### Database Connection Refused

```bash
# Check PostgreSQL service status
docker compose ps postgres

# View PostgreSQL logs
docker compose logs postgres

# Restart PostgreSQL
docker compose restart postgres
```

### Permission Denied Errors

```bash
# Ensure entrypoint script is executable
chmod +x docker-entrypoint.sh

# Rebuild image
docker compose build --no-cache
```

### Bundle Install Fails

```bash
# Remove bundle cache and rebuild
docker compose down -v
docker compose build --no-cache
docker compose up
```

### Database Doesn't Persist

Ensure you're not using `docker compose down -v` which removes volumes. Use `docker compose down` instead.

### Changes Not Reflecting

```bash
# For gem code changes
docker compose restart web

# For Gemfile changes
docker compose down
docker compose build
docker compose up

# For database schema changes
docker compose exec web rails db:migrate
```

## Performance Tips

1. **Use volumes for gems**: The `bundle_cache` volume speeds up builds significantly
2. **Avoid rebuilding**: Source code is mounted, so most changes don't require rebuild
3. **Clean up regularly**: Remove unused volumes and images
   ```bash
   docker system prune -a --volumes
   ```
4. **Use build cache**: Docker caches layers, so order matters in Dockerfile

## Testing the Setup

### Manual Verification

```bash
# Clean start
docker compose down -v
docker compose build
docker compose up -d

# Wait for services to be ready (about 30 seconds)
sleep 30

# Check services are running
docker compose ps

# Verify web app is accessible
curl http://localhost:3000

# Check database has data
docker compose exec web rails console
# In Rails console:
# User.count
# Post.count
# exit

# Test persistence
docker compose restart postgres
docker compose exec web rails console
# Verify data still exists
```

### Health Checks

```bash
# PostgreSQL health check
docker compose exec postgres pg_isready -U postgres

# Rails health check
curl http://localhost:3000/up
```

## Next Steps

After setting up the Docker environment:

1. **Explore the Web UI**: Visit [http://localhost:3000/better_structure_sql/schema_versions](http://localhost:3000/better_structure_sql/schema_versions)
2. **Test Schema Dumping**: Make changes and dump schema
3. **Browse Schema Versions**: View stored versions in the web interface
4. **Run Tests**: Execute the test suite in the container
5. **Develop Features**: Modify gem code and test in real-time

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Rails on Docker Best Practices](https://docs.docker.com/samples/rails/)
- [PostgreSQL Docker Hub](https://hub.docker.com/_/postgres)
