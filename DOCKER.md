# Docker Development Environment

Runs the integration app (`integration/`) and its PostgreSQL in containers, so the
only thing the host needs is Docker.

> **Have Ruby on the host?** `bin/setup` then `bin/dev` is the faster path: it runs the same
> app natively against a small private Postgres container (`bss-pg`). This file covers the
> all-in-Docker alternative. Both serve the same UI on port 3000 — run one at a time.

## What you get

| Service | Image | Reachable from the host |
|---|---|---|
| `postgres` | `postgres:17-alpine` | no — internal network only |
| `web` | built from `Dockerfile` (`ruby:4.0.10-alpine`, matches `.ruby-version`) | `http://127.0.0.1:3000` |

- The checkout is mounted at `/app`, so edits to the gem (`lib/`, `app/`) and to the
  integration app are live without a rebuild.
- PostgreSQL data and installed gems live in named volumes and survive restarts.

## Prerequisites

- Docker Engine 20.10+ with Compose v2 (`docker compose`)
- Port 3000 free on the host, or set `PORT`

## Quick start

```bash
docker compose up --build
```

First boot builds the image, waits for PostgreSQL, creates the database, loads the
schema from `integration/db/schema/` with the gem's own loader (`db:schema:load_better`),
seeds sample data and starts Rails. Later boots only apply pending migrations.

Open <http://127.0.0.1:3000/better_structure_sql/schema_versions> for the engine UI;
<http://127.0.0.1:3000> is the integration app's home page.

## Common commands

```bash
docker compose up -d               # start in the background
docker compose logs -f web         # follow Rails logs
docker compose restart web         # restart Rails (after changing initializers or the Gemfile)
docker compose down                # stop, keep data
docker compose down -v             # stop and delete the database and gem volumes
PORT=3001 docker compose up        # serve on another host port
```

Commands inside the `web` container run from `/app/integration`:

```bash
docker compose exec web bin/rails console
docker compose exec web bin/rails dbconsole
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails db:seed          # resets the sample data
```

### BetterStructureSql tasks

```bash
docker compose exec web bin/rails db:schema:dump_better   # dump to integration/db/schema/
docker compose exec web bin/rails db:schema:load_better   # load that dump
docker compose exec web bin/rails db:schema:store         # store the current schema as a version
docker compose exec web bin/rails db:schema:versions      # list stored versions
docker compose exec web bin/rails db:schema:cleanup       # apply the retention limit
```

### Tests

The gem's test suite runs on the host, not in this container: `bin/check` (see
[CONTRIBUTING.md](CONTRIBUTING.md)).

## Configuration

`docker-compose.yml` sets the variables `integration/config/database.yml` reads:

| Variable | Value | Meaning |
|---|---|---|
| `DB_HOST` | `postgres` | PostgreSQL service hostname |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USERNAME` / `DB_PASSWORD` | `postgres` / `postgres` | credentials (local development only) |
| `DB_NAME` | `better_structure_sql_development` | development database |
| `DB_TEST_NAME` | `better_structure_sql_test` | test database |
| `RAILS_ENV` | `development` | Rails environment |

Host-side knobs: `PORT` (host port for the web UI, default 3000), `USER_ID` / `GROUP_ID`
(build args, default 1000 — set them to `id -u` / `id -g` if yours differ so files written
to the mounted checkout stay yours).

## Volumes

| Volume | Holds | Reset with |
|---|---|---|
| `postgres17_data` | PostgreSQL data directory (named per major version) | `docker compose down -v` |
| `bundle_cache` | installed gems (`/usr/local/bundle`) | `docker compose down -v` |

## Files

| File | Role |
|---|---|
| `Dockerfile` | dev image: Ruby, build tools, the integration app's bundle |
| `docker-compose.yml` | the two services, volumes, network |
| `docker-entrypoint.sh` | waits for PostgreSQL, prepares the database, then runs the command |
| `integration/db/init.sql` | extensions created when the PostgreSQL volume is first initialised |
| `docker-compose.mysql.yml`, `Dockerfile.mysql` | the MySQL integration app (`integration_mysql/`) |

## Troubleshooting

**Port 3000 already in use** — `bin/dev` may be running on the host (`bin/stop`), or pick
another port: `PORT=3001 docker compose up`.

**`web` exits during startup** — read `docker compose logs web`. A failed schema load or
seed stops the container on purpose; fix the cause and `docker compose up` again.

**PostgreSQL will not start after an image upgrade** — a data directory written by another
major version cannot be reused. The volume is named per major version to avoid this; if you
changed the image yourself, `docker compose down -v` and start again (deletes local data).

**Gem errors after changing a Gemfile** — the entrypoint runs `bundle install` when the
bundle is out of date. If the volume is beyond repair: `docker compose down -v`, then
`docker compose up --build`.

**Changing the Ruby version** — update `.ruby-version` and the `FROM` line in `Dockerfile`
together, then `docker compose build`.

**Files in the checkout owned by another user** — rebuild with your ids:
`USER_ID=$(id -u) GROUP_ID=$(id -g) docker compose build`.
