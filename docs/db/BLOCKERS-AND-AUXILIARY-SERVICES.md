# Blocker review and auxiliary-service verification

Reviewed 2026-10-01. This follow-up inspected source, Docker metadata, HTTP probes and PostgreSQL catalogs read-only. Only documentation was changed. No containers, credentials, grants or data were changed.

Additional evidence tags here: `[RUNTIME]` means sanitized Docker metadata or
read-only HTTP/health probes; `[TEST]` means the recorded local Go test result.
They supplement the original catalog/source evidence tags.

## Blockers and recommended resolution

| Finding | Evidence and interpretation | Resolution |
|---|---|---|
| DB-02: missing legacy platform creation chain | The execution report records a successful restored upgrade but no clean bootstrap. `platform-api/archive/legacy-platform-monolith/migrations` contains only `0019_web_push_subscriptions.sql`; this is partial provenance, not the foundational creation chain. The existing data-free live DDL snapshot is available. [DOC][CODE] | Search tracked history and archives first. If source remains unavailable, adopt a new, explicitly dated catalog baseline for clean installations. Preserve existing historical ledger rows; label the baseline as a new adoption, not recovered history. Verify fresh and restored-upgrade convergence. |
| GO-03: owner-authenticated engine connections | Sanitized Docker inspection: taskgen/grader both authenticate as `mathprep` with startup `options=-c role=taskgen_svc/grader_svc`. `pg_stat_activity.usename` confirms `mathprep`; that login is superuser. Switching current role does not eliminate the privileged session identity. [DB][CODE][RUNTIME] | Provision separate local non-owner login identities through a private secret file, grant only the relevant group membership, and replace each service DSN. Credential absence is a local provisioning task, not inherently an external blocker. Production secret delivery remains a separate environment decision. |
| DB-03: future broad access through default ACL | Live `pg_default_acl` includes `mathprep_owner/mathprep` table rights for `mathprep_app`, and `mathprep/public` default table `arwd` plus sequence `rwU` rights for taskgen/grader. Existing documentation claiming no default ACL is wrong. [DB] | Review/revoke only the overbroad defaults after rehearsal; preserve required explicit grants. Test newly created synthetic objects under each actual creator identity. Existing-object revocation alone does not fix future access. |
| Migrator cannot fulfill its declared contract | All 128 tables are owned by `mathprep`. `mathprep_migrator` belongs to `mathprep_owner`, but neither has CREATE on `public` or `mathprep`; migrator cannot INSERT the ledger or UPDATE `public.task_type`, and lacks database CREATE. [DB] | Establish a deliberate migration authority model. A role membership alone does not convey ownership of objects owned by another role. Rehearse bounded ownership/grant changes or another documented dedicated administrative executor; runtime identities must not acquire this authority. |
| Fresh-bootstrap gate was coupled to live credential cutover | Clean bootstrap and live-upgrade compatibility are separate acceptance tests. Missing historical DDL does not by itself prevent testing new runtime logins against a restored snapshot. [INFERRED] | Proceed with credential/grant rehearsal independently. Keep DB-02 open until fresh bootstrap passes; require relevant restored-upgrade and rollback gates before live rollout. |
| GO-04 release interpretation conflicts with the requested rule | Execution record marks tagging unnecessary because only migrations/docs changed; the original requirement says schema changes ship under a new immutable tag. [DOC] | Publish a new schema contract tag when changes are complete, including SQL-only changes. Update consumers only where required by the changed module/contract; do not move existing tags. Record inability to publish separately from prepared release work. |

The execution record's original `BLOCKED` statuses are historical observations. This review does not mark those tasks complete; it identifies concrete ways to unblock them.

## Auxiliary services: persistence and actual runtime

| Component | Current implementation and persistence | Docker verification | Conclusion |
|---|---|---|---|
| Auth, `auxiliary/auth` | `cmd/server/main.go:45-75` selects Platform API when `PLATFORM_API_URL` is set, bypassing legacy `db.InitDB()`. `AUTH_PLATFORM_SESSION_MODE=redis` selects `platformsession.RedisStore`; OTP also uses Redis. Persistent principals/accounts remain accessed through authenticated Platform API HTTP operations. [CODE] | `mathprep-platform-local-auth-1`, image `sha256:008202c742f4…`, healthy, zero restarts; `PLATFORM_API_URL=http://platform-api:8090`, Redis mode; GET port 4324 `/healthz` = 200. No database URL configured. [RUNTIME] | No direct PostgreSQL is deliberate. It uses a database (Redis), and indirect PostgreSQL through Platform API. Health establishes process availability, not complete registration/login/OTP correctness. |
| Payments, active `payments` repo | `payments/AGENTS.md` explicitly forbids direct PostgreSQL. `cmd/mathprep-payments/main.go:87-173` sends authenticated context/session/result requests to Platform API; Platform API owns orders, attempts and entitlements in PostgreSQL. [CODE] | `mathprep-platform-local-payments-1`, image `sha256:a6c4541fe292…`, healthy, zero restarts; GET port 8092 `/healthz` and `/readyz` = 200; response reports `halyk_epay=true`, `xpayment=false`. [RUNTIME] | Stateless provider adapter is intentional. Halyk configuration is present but actual provider success is unverified. xpayment is disabled, not a crashed service. No payment/callback was executed during this review. |
| Legacy Kaspi, `auxiliary/kaspi` | Legacy `internal/adapters/repo/pg` exists, plus a payment-adapter prototype. Neither proves deployment. Existing local build mapping uses sibling `payments`, not this repository. [CODE] | No running separate Kaspi container in `docker ps -a` inventory. [RUNTIME] | Treat as legacy source/provenance. Do not start it or create its DB merely to eliminate an apparent discrepancy. |
| Notifications | Direct PostgreSQL connection as `mathprep_notifications_svc`; outbox enabled. [RUNTIME][DB] | Healthy, zero restarts; port 8091 `/healthz` and `/readyz` = 200. [RUNTIME] | Not a database-free service. Current readiness passes; live notification delivery was not triggered. |
| Redis | Shared Auth session/challenge storage; persistent configuration uses AOF. [CODE] `deploy/local/docker-compose.yml:8-13` | Running healthy. Unauthenticated PING returns NOAUTH as expected. Re-executing the configured authenticated healthcheck exits 0; its `grep -q PONG` deliberately suppresses the response. [RUNTIME] | Authentication is enabled; configured healthcheck succeeds. No keys/values were read. |

Platform API also uses `PLATFORM_AUTH_INTROSPECTION_URL=http://auth:4324` in the launcher; `cmd/platform-api/main.go:245-255` and Auth's `/internal/platform/sessions/introspect` provide the reverse session-validation boundary. [CODE] Identity HTTP dependencies are intentional in this newer platform topology; engine-only zero-network ADR wording does not describe all auxiliary boundaries.

## Correctness checks and limits

- Auth targeted tests passed: `GOTOOLCHAIN=auto go test ./internal/platformclient ./internal/platformsession ./internal/server ./internal/config` (cached). These do not prove a live Redis session or a user journey. [TEST]
- Payments suite passed: `GOTOOLCHAIN=auto go test ./...` (cached). Provider-client tests establish tested code behavior, not live provider credentials or settlement. [TEST]
- Platform API `/healthz` and `/readyz` = 200. Notifications equivalent endpoints = 200. Taskgen unauthenticated probes = 401, grader probes = 404; both actual `/app/healthcheck` executables exit 0. Missing public endpoints are not evidence that those containers are broken. [RUNTIME][CODE]
- Auth `/healthz` is unconditional HTTP success (`internal/server/server.go:84-88`). Payments `/readyz` reports configured provider booleans, without calling upstream or providers (`cmd/mathprep-payments/main.go:191-197`). Readiness coverage is therefore limited. [CODE]
- Active containers carry `com.docker.compose.service` labels, and `deploy/local/docker-compose.yml` maps Auth to `auxiliary/auth`, Payments to `payments`. Existing deployment is Compose-managed despite earlier assumptions. No launcher was changed. Future requested rollout must use explicit `docker run`, documenting transition and preserving network aliases. [RUNTIME][CODE]
- Neither Auth nor Payments has a source bind mount. Source test success cannot establish that the running images include latest source changes. Build revision/SBOM or controlled rebuild is needed. [RUNTIME][INFERRED]
- Live DB remains `public=33`, `mathprep=95`, migration ledger=53 rows, maximum label `0053_engine_service_least_privilege`. CAS has source but no active container in the inspected runtime. [DB][RUNTIME]

## Verification queries

All database sessions used `PGOPTIONS='-c default_transaction_read_only=on'`.

```sql
SELECT rolname, rolsuper, rolcanlogin, rolcreaterole, rolcreatedb
FROM pg_roles WHERE rolname !~ '^pg_' ORDER BY 1;
SELECT p.rolname, m.rolname FROM pg_auth_members a
JOIN pg_roles p ON p.oid=a.roleid JOIN pg_roles m ON m.oid=a.member;
SELECT defaclrole::regrole, defaclnamespace::regnamespace,
       defaclobjtype, defaclacl FROM pg_default_acl;
SELECT r.rolname, has_schema_privilege(r.oid,'mathprep','CREATE'),
       has_schema_privilege(r.oid,'public','CREATE')
FROM pg_roles r WHERE r.rolname IN ('mathprep_migrator','mathprep_owner');
SELECT has_table_privilege('mathprep_migrator','mathprep.schema_migrations','INSERT');
SELECT n.nspname, pg_get_userbyid(c.relowner), count(*)
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('public','mathprep') AND c.relkind IN ('r','p') GROUP BY 1,2;
SELECT usename, application_name, state, count(*) FROM pg_stat_activity
WHERE datname='mathprep' GROUP BY 1,2,3;
SELECT count(*), max(version) FROM mathprep.schema_migrations;
```

Runtime metadata was parsed before output: only configuration key names, nonsecret mode values, DSN username/host/database/options, image IDs and health results were retained. No raw Docker environment or request logs were printed.

## Resolution record, 2026-10-01

DB-02, DB-03, GO-03, DB-05, GO-05, DB-06, and GO-06 are resolved locally.
`catalog-baseline-2026-10-01` was adopted with the new `9000` marker, and
`0054_default_acl_and_migration_runner` removed the verified broad defaults.
Fresh bootstrap and restored upgrade normalized to the same catalog hash.
Taskgen and grader were rebuilt and launched through explicit `docker run`
commands with protected, non-owner local logins; their old Compose containers
are retained stopped under rollback names. Platform API was rebuilt and
replaced after them. Auth remains Redis/platform-API mediated, notifications
remains its limited direct PostgreSQL consumer, Payments remains stateless, and
legacy Kaspi remains undeployed. Production secret distribution and external
tag publication were intentionally not performed.
