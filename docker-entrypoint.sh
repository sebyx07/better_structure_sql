#!/bin/sh
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/integration/tmp/pids/server.pid

# Wait for postgres to be ready
echo "Waiting for PostgreSQL to be ready..."
until nc -z "$DATABASE_HOST" 5432 2>/dev/null; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - continuing"

# Navigate to integration app
cd /app/integration

# Install dependencies if needed
bundle check || bundle install

# Run database migrations
echo "Running database migrations..."
bundle exec rails db:create db:migrate 2>/dev/null || bundle exec rails db:migrate

# Seed the database if needed
if [ "$RAILS_ENV" = "development" ]; then
  echo "Seeding database..."
  bundle exec rails db:seed
fi

# Execute the container's main process
exec "$@"
