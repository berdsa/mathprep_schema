# Database remediation execution record

Started: 2026-10-01. Accountable owners are shown per task. Status is factual:
`DONE`, `BLOCKED`, `NOT_APPLICABLE`, or `PENDING`; no prepared runbook is
reported as a completed cutover.

## Contract and critical path

The verified target is `public` = engine and `mathprep` = platform. Existing
cross-schema contracts are intentional only where current source proves them:
Platform API creates/updates `public.users` and `public.students`, reads engine
learning data, and owns public billing tables; taskgen/grader/CAS own engine
workflows. [CODE] `platform-api/internal/platformidentity/http.go:600-940`,
`taskgen/internal/repository/generation.go:49-284`,
`grader/internal/server/server.go:109-214`.

Critical path: `DB-00 -> DB-01 -> DB-02 -> DB-03 -> GO-03 -> DB-04 ->
DB-05 -> GO-05`; `GO-00` is complete and supplies DB-03/04, while GO-01/02
can proceed after DB-01. GO-04 cannot complete until an immutable schema tag
is published and consumers resolve it.

| Task | Owner | Repository | Steps / acceptance / rollback | Status |
|---|---|---|---|---|
| DB-00 | Senior DB Engineer | schema / restricted backup location | Captured restricted two-schema custom dump plus globals at `/private/tmp/mathprep-remediation.BabRca` (mode 0700/0600), restored `mathprep_remediation_rehearsal_20261001`, and compared table totals, FK validity, and negative/positive grants. The normalized schema dump fingerprint was `c8f607352358adac28499db91741a0d357a21cd253e25878e6df6c2ad07b9a1d`; raw `pg_dump` restriction tokens were excluded. Restore initially changed the default `PUBLIC` USAGE ACL on `public`; adding that standard grant in the isolated database produced an exact normalized catalog match. Rollback is retained backup plus previous container configuration. | DONE |
| GO-00 | Senior Go Developer | all discovered Go backends | Complete SQL manifest and table-use audit; cover reachable production SQL, DSN/search-path and role switching. Evidence: `UNUSED-TABLES-AUDIT.md`. | DONE |
| DB-01 | Senior DB Engineer | schema | Recorded the two-schema contract, migration ownership, explicit bridge, runtime/group roles, denials, and explicit-grant/default-privilege policy in `SCHEMA-OWNERSHIP-AND-PRIVILEGES.md`; reconciled `docs/srd/03-architecture.md`. | DONE |
| DB-02 | Senior DB Engineer | schema | Added `MIGRATION-STREAM-MANIFEST.md` and recorded the actual `000131` application as ledger `0053_engine_service_least_privilege`, without backfilling history. Restored-upgrade rehearsal is proven; fresh convergence remains blocked because platform base DDL is absent, documented in `deploy/local/docs/platform-schema-source-gaps.md:1-45`. | BLOCKED |
| DB-03 | Senior DB Engineer | schema | `000131_engine_service_least_privilege` was rehearsed on the restored snapshot and applied live as ledger `0053_engine_service_least_privilege` (`dd866f…8bb911d`). It revokes taskgen/grader billing access, removes grader task-instance mutation, preserves taskgen generation and grader submission rights, and grants CAS queue lifecycle updates. Positive rolled-back mutation probes and negative denial probes passed in the isolated DB. Platform-role/default-privilege review remains. | PENDING |
| DB-04 | Senior DB Engineer | schema | Catalog revalidation found no invalid indexes, no unvalidated FKs, no partitions, and no demonstrated query-plan integrity/performance gap requiring DDL. No speculative index or constraint was added. | NOT_APPLICABLE |
| GO-01 | Senior Go Developer | taskgen, grader, cas | All reachable engine SQL is qualified as `public.*`: taskgen `14dba5a`, grader `16aae00`, CAS `b33a11e`. `GOTOOLCHAIN=auto go test ./...` passed in each repository; qualified reads also succeeded under `search_path=pg_catalog`. | DONE |
| GO-02 | Senior Go Developer | platform-api, notifications, payments, auxiliary/auth | Reachable PA/NT SQL qualifies platform relations as `mathprep.*` and engine bridge relations as `public.*`; payments has no DB client. Auth is in platform-session mode, so its legacy `mathprep_auth` direct DB path is not reached. The bridge and limitation are documented in the audit. | DONE |
| GO-03 | Senior Go Developer | each active service | Existing taskgen/grader connections authenticate as the `mathprep` owner then use connection-level `SET ROLE` to group roles. Although resulting permissions are now restricted, the session can reset to the owner; dedicated non-owner login credentials and secret distribution are not available in the workspace. Do not claim this boundary is complete. | BLOCKED |
| GO-04 | Senior Go Developer | schema + consumers | Verified module path `github.com/berdsa/mathprep_schema`, GitHub remote, and existing immutable `v0.3.10` consumer pins. This remediation changes migrations/docs only, not the shared Go module, so no new tag or consumer update is appropriate. Tracked local `replace ../schema` directives are existing development wiring and were not introduced or altered. | NOT_APPLICABLE |
| DB-05 | Senior DB Engineer | schema / deploy runbook | Bounded writer freeze only if needed, service-by-service readiness, pre/post checks, explicit previous-image/config recovery. | PENDING — cannot claim live cutover before DB-00 through DB-04. |
| GO-05 | Senior Go Developer | active services | Unit/integration-style suites passed for platform-api, notifications, payments, and Auth in addition to engine services. Live containers remained healthy after the grant migration. Full synthetic end-to-end matrix and image-by-image rollout cannot run until GO-03 supplies non-owner runtime credentials and DB-02 resolves fresh platform bootstrap. | PENDING |
| DB-06 | Senior DB Engineer | schema docs | Re-query final catalog, update DB documentation, retain candidates; remove compatibility grants only after observation gate. | PENDING |
| GO-06 | Senior Go Developer | taskgen, grader, cas, schema | `GOTOOLCHAIN=auto go test ./...`, `go vet ./...`, and `go build ./...` passed in taskgen/grader/CAS; schema tests passed. Task-owned commits are `14dba5a`, `16aae00`, `b33a11e`, `90da9e2`, `d21b488`, `a61f443`, and `8fd6fcf`; remaining release/cutover work prevents final closure. | PENDING |

## Verified migration and role facts

`mathprep.schema_migrations` has 52 rows; it is the only live ledger. `public`
has no migration ledger. The ledger contains a legacy platform stream plus
canonical mappings, and the active platform API readiness check validates
specific version/checksum pairs. [DB] `SELECT version, left(checksum,16) FROM
mathprep.schema_migrations`; [CODE] `platform-api/cmd/platform-api/main.go:45-58`;
[MIGRATION] `schema/migrations/000094_generation_request_locale.up.sql` and
`000099` onward.

Service roles `taskgen_svc`, `grader_svc`, `cas_svc`, and `platform_api_svc`
are `NOLOGIN` group roles, while local login roles inherit effective rights.
This is intentional design evidence, not a failure to be "fixed" by making
the group roles login roles. `mathprep_app`/`mathprep_migrator` set
`search_path=mathprep, pg_catalog`; engine group roles do not have a role-level
path, so unqualified engine SQL resolves through default `public`. [DB]
`pg_roles` and `pg_db_role_setting` query 2026-10-01.

## Cutover and recovery runbook (prepared, not executed)

1. Stop writers only after DB-00 backup/restore passes and record the bounded
   window. Capture image digests/config key names without DSN values.
2. Preflight the live ledger/checksums, schema fingerprints, effective grants,
   and service readiness. Abort on any mismatch.
3. Apply one validated additive migration using the migrator identity with
   `lock_timeout` and `statement_timeout`; recheck catalog and grant matrix.
4. Launch each independent service using its existing `docker run` topology
   (the existing local Compose launcher is not introduced or expanded here),
   and verify readiness before advancing.
5. On failure, stop only the affected service, restore its previous image and
   configuration; revoke only new grants or use the validated migration down
   procedure where safe. Use logical restore only for data corruption.

Required isolated-fixture checks remain: generation idempotency/leases and
frozen answers; grading verdict/retry/UNPARSEABLE/mastery and no task-instance
write; CAS queue receipt/duplicate/timeout; platform tenant bridge; outbox
lease/dedup/quiet-hours; billing correlation; fresh/upgrade migration and
restore. No write-capable integration test will target live data.
