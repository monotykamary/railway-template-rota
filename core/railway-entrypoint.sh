#!/bin/sh
set -eu

: "${DB_HOST:?DB_HOST is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"
: "${DB_NAME:?DB_NAME is required}"
: "${ROTA_PROXY_USER:?ROTA_PROXY_USER is required}"
: "${ROTA_PROXY_PASSWORD:?ROTA_PROXY_PASSWORD is required}"

export PGPASSWORD="$DB_PASSWORD"
export PGSSLMODE="${DB_SSLMODE:-disable}"

run_psql() {
  psql \
    --host="$DB_HOST" \
    --port="${DB_PORT:-5432}" \
    --username="$DB_USER" \
    --dbname="$DB_NAME" \
    "$@"
}

wait_limit="${ROTA_DB_WAIT_SECONDS:-180}"
attempt=0
until run_psql -Atqc 'SELECT 1' >/dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge "$wait_limit" ]; then
    echo "Timed out waiting for TimescaleDB" >&2
    exit 1
  fi
  sleep 1
done

bootstrap_pid=""
stop_bootstrap() {
  if [ -n "$bootstrap_pid" ] && kill -0 "$bootstrap_pid" 2>/dev/null; then
    kill -TERM "$bootstrap_pid" 2>/dev/null || true
    wait "$bootstrap_pid" 2>/dev/null || true
  fi
}
trap 'stop_bootstrap; exit 143' TERM
trap 'stop_bootstrap; exit 130' INT

settings_exists="$(run_psql -Atqc "SELECT to_regclass('public.settings') IS NOT NULL")"
if [ "$settings_exists" != "t" ]; then
  echo "Initializing Rota schema"
  /app/server &
  bootstrap_pid="$!"
  attempt=0
  until wget --quiet --output-document=/dev/null "http://127.0.0.1:${API_PORT:-8001}/health" 2>/dev/null; do
    if ! kill -0 "$bootstrap_pid" 2>/dev/null; then
      wait "$bootstrap_pid" || true
      echo "Rota exited before schema initialization completed" >&2
      exit 1
    fi
    attempt=$((attempt + 1))
    if [ "$attempt" -ge "$wait_limit" ]; then
      echo "Timed out waiting for Rota schema initialization" >&2
      stop_bootstrap
      exit 1
    fi
    sleep 1
  done
  stop_bootstrap
  bootstrap_pid=""
fi

run_psql --set=ON_ERROR_STOP=1 <<'SQL'
\getenv proxy_user ROTA_PROXY_USER
\getenv proxy_password ROTA_PROXY_PASSWORD
INSERT INTO settings (key, value, updated_at)
VALUES (
  'authentication',
  jsonb_build_object(
    'enabled', true,
    'username', :'proxy_user',
    'password', :'proxy_password'
  ),
  NOW()
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    updated_at = NOW();
SQL

echo "Incoming proxy authentication is enabled"
exec /app/server
