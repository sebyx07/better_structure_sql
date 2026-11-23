# shellcheck shell=bash
# Shared helpers for bin/setup, bin/check, bin/dev and bin/stop. Sourced, never run.
# shellcheck disable=SC2034  # variables here are read by the scripts that source this file
#
# Exit codes used by every script:
#   0   success
#   75  an environment prerequisite is missing (ruby, gems, docker, Postgres) —
#       the script refused to run; fix the box (usually `bin/setup`), not the code
#   *   the script ran and something failed

EX_ENV=75

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The private Postgres this repo owns. Override only to run a second instance.
BSS_PG_CONTAINER="${BSS_PG_CONTAINER:-bss-pg}"
BSS_PG_PORT="${BSS_PG_PORT:-55432}"
BSS_PG_IMAGE="${BSS_PG_IMAGE:-postgres:17-alpine}"
BSS_PG_SERVER_URL="postgresql://postgres:postgres@127.0.0.1:${BSS_PG_PORT}"
DEFAULT_DATABASE_URL="${BSS_PG_SERVER_URL}/better_structure_sql_test"

# State bin/stop needs to undo exactly what bin/setup and bin/dev started.
DX_STATE_DIR="$ROOT/tmp/dx"
PG_STARTED_MARKER="$DX_STATE_DIR/pg-started-by-setup"
DEV_PID_FILE="$ROOT/integration/tmp/pids/server.pid"

step() { printf '\n▸ %s\n' "$*"; }
ok() { printf '  ✔ %s\n' "$*"; }

# env_missing <what is missing> <how to fix it> — exits 75.
env_missing() {
  {
    printf '\nENVIRONMENT MISSING (exit %s): %s\n' "$EX_ENV" "$1"
    printf '  fix: %s\n' "$2"
  } >&2
  exit "$EX_ENV"
}

# Puts the Ruby named in .ruby-version first on PATH (mise, then rbenv).
# `use_ruby install` also installs it; without the argument a missing Ruby is exit 75.
use_ruby() {
  local want have dir
  want="$(tr -d '[:space:]' <"$ROOT/.ruby-version")"
  want="${want#ruby-}"

  if command -v mise >/dev/null 2>&1; then
    # mise refuses to resolve anything next to an untrusted mise.toml. Trust the repo's
    # own file for this process; bin/setup also records the trust so plain `ruby` and
    # `bundle` work in your shell.
    export MISE_TRUSTED_CONFIG_PATHS="$ROOT${MISE_TRUSTED_CONFIG_PATHS:+:$MISE_TRUSTED_CONFIG_PATHS}"
    if [ "${1:-}" = install ] && [ -f "$ROOT/mise.toml" ]; then mise trust --quiet "$ROOT/mise.toml"; fi
    if [ "${1:-}" = install ] && ! mise where "ruby@$want" >/dev/null 2>&1; then
      mise install "ruby@$want" ||
        env_missing "mise could not install ruby $want" "mise install ruby@$want"
    fi
    # The real bin dir, not the shim: shims re-resolve the version per directory
    # and integration/ carries its own .ruby-version.
    if dir="$(mise where "ruby@$want" 2>/dev/null)"; then PATH="$dir/bin:$PATH"; fi
  elif command -v rbenv >/dev/null 2>&1; then
    if [ "${1:-}" = install ]; then
      rbenv install --skip-existing "$want" ||
        env_missing "rbenv could not install ruby $want" "rbenv install $want"
    fi
    export RBENV_VERSION="$want"
    PATH="$(rbenv root)/shims:$PATH"
  fi
  export PATH

  have="$(ruby -e 'print RUBY_VERSION' 2>/dev/null || true)"
  [ -n "$have" ] ||
    env_missing "ruby $want is not installed" "install mise (https://mise.jdx.dev) or rbenv, then run bin/setup"
  [ "$have" = "$want" ] ||
    env_missing "ruby $have is active but .ruby-version wants $want" "run bin/setup (installs it through mise or rbenv)"
}

# require_gems [dir] — exit 75 unless the bundle in dir (default: repo root) is installed.
require_gems() {
  local dir="${1:-$ROOT}" label="the gem"
  [ "$dir" = "$ROOT" ] || label="${dir#"$ROOT"/}/"
  (cd "$dir" && bundle check >/dev/null 2>&1) ||
    env_missing "the bundle for $label is not installed (or Gemfile.lock changed)" "bin/setup"
}

# pg_probe <url> — 0: database reachable · 2: server reachable, database missing · 1: unreachable.
pg_probe() {
  (cd "$ROOT" && bundle exec ruby -rpg -e '
    begin
      PG.connect(ARGV[0], connect_timeout: 3).close
    rescue PG::ConnectionBad => e
      exit(e.message.match?(/database ".*" does not exist/) ? 2 : 1)
    end
  ' "$1") 2>/dev/null
}

# pg_create_database <url> — creates the database named in the URL.
pg_create_database() {
  (cd "$ROOT" && bundle exec ruby -rpg -ruri -e '
    uri = URI.parse(ARGV[0])
    name = uri.path.delete_prefix("/")
    uri.path = "/postgres"
    conn = PG.connect(uri.to_s, connect_timeout: 3)
    conn.exec("CREATE DATABASE #{conn.quote_ident(name)}")
    conn.close
  ' "$1")
}

# Password-free form of a database URL, for messages.
redact_url() { printf '%s' "$1" | sed -E 's#(://[^:/@]+):[^@]*@#\1:***@#'; }
