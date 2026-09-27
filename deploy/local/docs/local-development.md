# Local development and deployment

The local platform is run from the sibling repositories under `/Users/saken/code/math`. The schema repo owns database migrations and the service startup helper; the Lovable web checkout is kept separately at `/Users/saken/code/math/frontend/lovable/learn-path-kz`.

## Database and service startup

From the schema repo, run `scripts/start-local.sh`. It starts a standalone PostgreSQL 16 container (no compose), applies the ordered `migrations/*.up.sql` files only when `public.task_type` is absent, then starts taskgen and grader as background Go processes.

Defaults: PostgreSQL `127.0.0.1:5432`, database/user `mathprep`, password `phase0-local-only-change-me`; taskgen `:8081`; grader `:8082`. Override with `MATHPREP_PG_CONTAINER`, `MATHPREP_PG_PORT`, `MATHPREP_DB_USER`, `MATHPREP_DB_NAME`, `MATHPREP_DB_PASSWORD`, `DATABASE_URL`, `TASKGEN_HTTP_ADDR`, and `GRADER_ADDR`. Use a URL-safe local password if overriding `DATABASE_URL` implicitly. Logs and PID files go to the ignored `schema/.local-run/` directory. Existing databases are not migrated automatically: apply subsequent migrations explicitly after reviewing them.

Requires Docker, Go (the repos' declared toolchain), `lsof`, and `rg`. Stop the two service PIDs manually (`kill "$(cat schema/.local-run/taskgen.pid)"` and likewise for grader); PostgreSQL remains available in its named container and persistent volume.

## Lovable web checkout

The web repository is the GitLab-connected checkout at `/Users/saken/code/math/frontend/lovable/learn-path-kz`. Run its checks from that directory:

```sh
cd /Users/saken/code/math/frontend/lovable/learn-path-kz
npm ci
npm test -- --run
npm run typecheck
npm run build
```

The browser talks to the local platform API at `http://127.0.0.1:8090` by default. Set `VITE_API_BASE_URL` in the local frontend environment when using another API address.

## Refreshing the local Docker web container

The checked-in local platform currently has no compose file in this workspace. Build the web image from the Lovable checkout using a temporary Docker context so generated Docker files do not become frontend source:

```sh
cd /Users/saken/code/math
build_context="$(mktemp -d /tmp/mathprep-web-build.XXXXXX)"
rsync -a --delete \
  --exclude .git --exclude node_modules --exclude .output --exclude .wrangler \
  frontend/lovable/learn-path-kz/ "$build_context/"
cp schema/deploy/local/web.Dockerfile "$build_context/"
docker build --file "$build_context/web.Dockerfile" --tag mathprep-platform-web:local "$build_context"
```

Replace the running web container while preserving its local network and port:

```sh
docker rename mathprep-platform-local-web-1 mathprep-platform-local-web-previous
docker run -d --name mathprep-platform-local-web-1 \
  --network mathprep-platform-local --network-alias web \
  --restart unless-stopped -p 127.0.0.1:5173:8080 \
  --health-cmd='node -e "fetch(\"http://127.0.0.1:8080/\").then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"' \
  --health-interval=5s --health-timeout=5s --health-start-period=10s --health-retries=12 \
  mathprep-platform-web:local
docker rm -f mathprep-platform-local-web-previous
```

Verify `http://127.0.0.1:5173`, a successful `GET /`, and all local containers before removing the previous container. Keep the previous container instead of removing it when a rollback is needed.
