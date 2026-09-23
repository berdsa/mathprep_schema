#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATHPREP_PG_CONTAINER="${MATHPREP_PG_CONTAINER:-postgres}"
MATHPREP_PG_PORT="${MATHPREP_PG_PORT:-5432}"
MATHPREP_DB_USER="${MATHPREP_DB_USER:-mathprep}"
MATHPREP_DB_NAME="${MATHPREP_DB_NAME:-mathprep}"
MATHPREP_DB_PASSWORD="${MATHPREP_DB_PASSWORD:-phase0-local-only-change-me}"
TASKGEN_HTTP_ADDR="${TASKGEN_HTTP_ADDR:-:8081}"
GRADER_ADDR="${GRADER_ADDR:-:8082}"
DATABASE_URL="${DATABASE_URL:-postgres://${MATHPREP_DB_USER}:${MATHPREP_DB_PASSWORD}@127.0.0.1:${MATHPREP_PG_PORT}/${MATHPREP_DB_NAME}?sslmode=disable}"

command -v docker >/dev/null || { echo 'docker is required' >&2; exit 1; }
command -v go >/dev/null || { echo 'go is required' >&2; exit 1; }

if ! docker inspect "$MATHPREP_PG_CONTAINER" >/dev/null 2>&1; then
  docker run -d --name "$MATHPREP_PG_CONTAINER" \
    -e "POSTGRES_USER=$MATHPREP_DB_USER" \
    -e "POSTGRES_PASSWORD=$MATHPREP_DB_PASSWORD" \
    -e "POSTGRES_DB=$MATHPREP_DB_NAME" \
    -p "${MATHPREP_PG_PORT}:5432" \
    -v mathprep_pgdata:/var/lib/postgresql/data postgres:16
else
  docker start "$MATHPREP_PG_CONTAINER" >/dev/null
fi

ready=0
for _ in $(seq 1 60); do
  if docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
      pg_isready -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [[ "$ready" != 1 ]]; then echo 'PostgreSQL did not become ready within 60 seconds' >&2; exit 1; fi

has_schema="$(docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
  psql -At -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" -c "SELECT to_regclass('public.task_type') IS NOT NULL")"
if [[ "$has_schema" != t ]]; then
  for migration in "$ROOT"/migrations/*.up.sql; do
    echo "Applying $(basename "$migration")"
    docker exec -i -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" < "$migration"
  done
else
  echo 'Existing task_type table found; migrations were not replayed.'
fi

mkdir -p "$ROOT/.local-run"
for service in taskgen grader; do
  repo="$ROOT/../$service"
  addr_var=TASKGEN_HTTP_ADDR
  addr="$TASKGEN_HTTP_ADDR"
  if [[ "$service" == grader ]]; then addr_var=GRADER_ADDR; addr="$GRADER_ADDR"; fi
  if lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | rg -q "${addr##*:}.*LISTEN"; then
    echo "A process is already listening on ${addr##*:}; refusing to start duplicate $service" >&2
    exit 1
  fi
  cd "$repo"
  nohup env GOTOOLCHAIN="${GOTOOLCHAIN:-auto}" DATABASE_URL="$DATABASE_URL" "$addr_var"="$addr" \
    go run ./cmd/"$service" > "$ROOT/.local-run/$service.log" 2>&1 < /dev/null &
  echo $! > "$ROOT/.local-run/$service.pid"
  cd "$ROOT"
done
for service_port in "${TASKGEN_HTTP_ADDR##*:}" "${GRADER_ADDR##*:}"; do
  listening=0
  for _ in $(seq 1 45); do
    if lsof -nP -iTCP:"$service_port" -sTCP:LISTEN 2>/dev/null | rg -q LISTEN; then listening=1; break; fi
    pid_file="$ROOT/.local-run/taskgen.pid"
    [[ "$service_port" == "${GRADER_ADDR##*:}" ]] && pid_file="$ROOT/.local-run/grader.pid"
    if ! kill -0 "$(cat "$pid_file")" 2>/dev/null; then break; fi
    sleep 1
  done
  if [[ "$listening" != 1 ]]; then
    echo "service failed to listen on port $service_port; inspect $ROOT/.local-run/*.log" >&2
    exit 1
  fi
done
stop_services() {
  for service in taskgen grader; do
    pid_file="$ROOT/.local-run/$service.pid"
    if [[ -f "$pid_file" ]]; then kill "$(cat "$pid_file")" 2>/dev/null || true; fi
  done
}
trap stop_services INT TERM EXIT
echo "PostgreSQL: 127.0.0.1:${MATHPREP_PG_PORT}/${MATHPREP_DB_NAME}"
echo "taskgen: ${TASKGEN_HTTP_ADDR} (log: $ROOT/.local-run/taskgen.log)"
echo "grader: ${GRADER_ADDR} (log: $ROOT/.local-run/grader.log)"
echo 'Services are running in the foreground session; press Ctrl-C to stop taskgen and grader.'
wait
