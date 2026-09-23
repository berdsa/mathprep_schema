# Local service startup

From the schema repo, run `scripts/start-local.sh`. It starts a standalone PostgreSQL 16 container (no compose), applies the ordered `migrations/*.up.sql` files only when `public.task_type` is absent, then starts taskgen and grader as background Go processes.

Defaults: PostgreSQL `127.0.0.1:5432`, database/user `mathprep`, password `phase0-local-only-change-me`; taskgen `:8081`; grader `:8082`. Override with `MATHPREP_PG_CONTAINER`, `MATHPREP_PG_PORT`, `MATHPREP_DB_USER`, `MATHPREP_DB_NAME`, `MATHPREP_DB_PASSWORD`, `DATABASE_URL`, `TASKGEN_HTTP_ADDR`, and `GRADER_ADDR`. Use a URL-safe local password if overriding `DATABASE_URL` implicitly. Logs and PID files go to the ignored `schema/.local-run/` directory. Existing databases are not migrated automatically: apply subsequent migrations explicitly after reviewing them.

Requires Docker, Go (the repos' declared toolchain), `lsof`, and `rg`. Stop the two service PIDs manually (`kill "$(cat schema/.local-run/taskgen.pid)"` and likewise for grader); PostgreSQL remains available in its named container and persistent volume.
