#!/usr/bin/env bash
# A small psql-based migration runner. DATABASE_URL is read from the process
# environment (or the caller's protected secret injection), never logged.
set -euo pipefail

usage() { echo "usage: DATABASE_URL=... $0 {apply|adopt} version sql-file" >&2; exit 64; }
[[ $# -eq 3 ]] || usage
[[ -n "${DATABASE_URL:-}" ]] || { echo 'DATABASE_URL is required' >&2; exit 64; }
command -v psql >/dev/null || { echo 'psql is required' >&2; exit 69; }

mode=$1; version=$2; sql_file=$3
[[ -r "$sql_file" ]] || { echo 'migration source is unreadable' >&2; exit 66; }
checksum=$(sha256sum "$sql_file" | awk '{print $1}')
[[ "$mode" == apply || "$mode" == adopt ]] || usage

control=$(mktemp)
trap 'rm -f "$control"' EXIT
cat >"$control" <<SQL
\\set ON_ERROR_STOP on
SET lock_timeout = '5s';
SET statement_timeout = '60s';
SELECT pg_advisory_lock(hashtext('mathprep-schema-migrations'));
CREATE TABLE IF NOT EXISTS mathprep.migration_runner_state (
  version varchar(64) PRIMARY KEY, checksum char(64) NOT NULL,
  state text NOT NULL CHECK (state IN ('running','failed','applied')),
  updated_at timestamptz NOT NULL DEFAULT now(), error_summary text
);
BEGIN;
DO \$\$ BEGIN
  IF EXISTS (SELECT 1 FROM mathprep.schema_migrations WHERE version = '$version' AND checksum <> '$checksum') THEN
    RAISE EXCEPTION 'checksum mismatch for %', '$version';
  ELSIF EXISTS (SELECT 1 FROM mathprep.schema_migrations WHERE version = '$version') THEN
    RAISE EXCEPTION 'version already applied: %', '$version';
  END IF;
END \$\$;
INSERT INTO mathprep.migration_runner_state(version, checksum, state, updated_at, error_summary)
VALUES ('$version','$checksum','running',now(),NULL)
ON CONFLICT (version) DO UPDATE SET checksum=EXCLUDED.checksum,state='running',updated_at=now(),error_summary=NULL;
\\i $sql_file
INSERT INTO mathprep.schema_migrations(version, checksum, applied_by)
VALUES ('$version','$checksum','catalog-runner')
ON CONFLICT (version) DO NOTHING;
UPDATE mathprep.migration_runner_state SET state='applied',updated_at=now(),error_summary=NULL WHERE version='$version';
COMMIT;
SELECT pg_advisory_unlock(hashtext('mathprep-schema-migrations'));
SQL
PGOPTIONS='-c default_transaction_read_only=off' psql -X --no-psqlrc "$DATABASE_URL" -f "$control" >/dev/null
