#!/bin/sh
# Entrypoint of the dev image: waits for Postgres, prepares the integration app's
# database, then runs the container command. Mirrors what bin/dev does on the host.
set -e

DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"

# A server.pid left behind by a killed container (or by bin/dev on the host) blocks boot
rm -f /app/integration/tmp/pids/server.pid

echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
until pg_isready --host "$DB_HOST" --port "$DB_PORT" --quiet; do
  sleep 1
done
echo "PostgreSQL is up"

cd /app/integration

# The checkout is mounted over /app, so the Gemfile may be newer than the image
bundle check >/dev/null 2>&1 || bundle install

if bundle exec rails runner 'exit(ActiveRecord::Base.connection.table_exists?("schema_migrations") ? 0 : 1)' 2>/dev/null; then
  # Existing database: migrate only when something is pending, because db:migrate
  # re-dumps the schema into the mounted checkout
  bundle exec rails db:abort_if_pending_migrations >/dev/null 2>&1 || bundle exec rails db:migrate
else
  echo "Loading schema and seeding sample data..."
  bundle exec rails db:create db:schema:load_better db:seed
fi

exec "$@"
