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

[[ "$MATHPREP_DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { echo 'MATHPREP_DB_NAME must contain only letters, digits, and underscores' >&2; exit 1; }

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

database_exists="$(docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
  psql -At -U "$MATHPREP_DB_USER" -d postgres \
  -c "SELECT 1 FROM pg_database WHERE datname = '$MATHPREP_DB_NAME'")"
if [[ "$database_exists" != 1 ]]; then
  docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
    createdb -U "$MATHPREP_DB_USER" "$MATHPREP_DB_NAME"
fi

EXISTING_SERVICE_ROLES="$(docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
  psql -At -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" \
  -c "SELECT COALESCE(string_agg(rolname, ','), '') FROM pg_roles WHERE rolname IN ('taskgen_svc','grader_svc','cas_svc')")"

apply_migration() {
  local migration="$1"
  if [[ -n "$EXISTING_SERVICE_ROLES" ]]; then
    MATHPREP_EXISTING_ROLES="$EXISTING_SERVICE_ROLES" awk '
      function role_exists(role, names, count, i) {
        count = split(ENVIRON["MATHPREP_EXISTING_ROLES"], names, ",")
        for (i = 1; i <= count; i++) if (names[i] == role) return 1
        return 0
      }
      /^CREATE ROLE / {
        role = $3
        if (role_exists(role)) { skipping = 1; next }
      }
      skipping { if ($0 ~ /NOINHERIT;/) skipping = 0; next }
      { print }
    ' "$migration" | docker exec -i -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME"
  else
    docker exec -i -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
      psql -v ON_ERROR_STOP=1 -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" < "$migration"
  fi
}

has_schema="$(docker exec -e "PGPASSWORD=$MATHPREP_DB_PASSWORD" "$MATHPREP_PG_CONTAINER" \
  psql -At -U "$MATHPREP_DB_USER" -d "$MATHPREP_DB_NAME" -c "SELECT to_regclass('public.task_type') IS NOT NULL")"
if [[ "$has_schema" != t ]]; then
  for migration in "$ROOT"/migrations/*.up.sql; do
    migration_version="${migration##*/}"
    migration_version="${migration_version%%_*}"
    migration_version=$((10#$migration_version))
    if (( migration_version >= 10 )); then continue; fi
    echo "Applying $(basename "$migration")"
    apply_migration "$migration"
  done

  apply_migration "$ROOT/migrations/000011_add_answer_widget_dictionary.up.sql"
  apply_migration "$ROOT/migrations/000012_add_task_type_widget_columns.up.sql"

  echo 'Reconciling the task_type catalog before applying template migrations'
  (
    cd "$ROOT/../taskgen"
    GOTOOLCHAIN="${GOTOOLCHAIN:-auto}" DATABASE_URL="$DATABASE_URL" TASKGEN_RECONCILE_ONLY=1 go run ./cmd/taskgen
  )

  for migration in "$ROOT"/migrations/*.up.sql; do
    migration_version="${migration##*/}"
    migration_version="${migration_version%%_*}"
    migration_version=$((10#$migration_version))
    if (( migration_version != 10 && (migration_version < 13 || migration_version >= 25) )); then continue; fi
    echo "Applying $(basename "$migration")"
    apply_migration "$migration"
  done
  for migration in "$ROOT"/migrations/*.up.sql; do
    migration_version="${migration##*/}"
    migration_version="${migration_version%%_*}"
    migration_version=$((10#$migration_version))
    if (( migration_version < 25 )); then continue; fi
    echo "Applying $(basename "$migration")"
    apply_migration "$migration"
  done
else
  echo 'Existing task_type table found; reconciling catalog before replaying idempotent Phase B template seeds.'
  (
    cd "$ROOT/../taskgen"
    GOTOOLCHAIN="${GOTOOLCHAIN:-auto}" DATABASE_URL="$DATABASE_URL" TASKGEN_RECONCILE_ONLY=1 go run ./cmd/taskgen
  )
  for migration in "$ROOT"/migrations/*.up.sql; do
    migration_version="${migration##*/}"
    migration_version="${migration_version%%_*}"
    migration_version=$((10#$migration_version))
    if (( migration_version < 25 )); then continue; fi
    echo "Applying $(basename "$migration")"
    apply_migration "$migration"
  done
fi

if [[ "${MATHPREP_BOOTSTRAP_ONLY:-0}" == 1 ]]; then
  echo 'Bootstrap migrations and task_type reconciliation completed; service startup skipped.'
  exit 0
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
