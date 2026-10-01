# Database remediation execution record

Started: 2026-10-01. Accountable owners are shown per task. Status is factual:
`DONE`, `BLOCKED`, `NOT_APPLICABLE`, or `PENDING`; no prepared runbook is
reported as a completed cutover.

## Follow-up review, 2026-10-01

The pasted response for `653e403` agrees with DB-02/GO-03 blockers below.
Historical task statuses remain preserved; this follow-up performed diagnosis
and documentation only. `BLOCKERS-AND-AUXILIARY-SERVICES.md` records evidence.

Resolution path: adopt a dated verified catalog baseline if full historical
source recovery fails; provision dedicated protected local logins; establish
effective migrator authority; reconcile existing broad default ACLs.
The review contradicts the earlier absent-defaults claim and found the
declared migrator lacks schema CREATE/ledger INSERT rights. Clean bootstrap
and restored-snapshot credential rehearsal can proceed independently.
GO-04's SQL-only tagging interpretation must also be reconciled with the
requested new schema-contract tag rule.

Auth uses Redis and indirect Platform API persistence; Payments deliberately
delegates persistence; legacy Kaspi is undeployed. Active inspected backend
containers are healthy, but full external workflows and source/image parity
remain unverified. `UNBLOCK-AND-COMPLETE-PROMPT.md` implements this path.

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
can proceed after DB-01. GO-04 is not on this path because the remediation did
not change the shared Go module.

| Task | Owner | Repository | Steps / acceptance / rollback | Status |
|---|---|---|---|---|
| DB-00 | Senior DB Engineer | schema / restricted backup location | Captured restricted two-schema custom dump plus globals at `/private/tmp/mathprep-remediation.BabRca` (mode 0700/0600), restored `mathprep_remediation_rehearsal_20261001`, and compared table totals, FK validity, and negative/positive grants. The normalized schema dump fingerprint was `c8f607352358adac28499db91741a0d357a21cd253e25878e6df6c2ad07b9a1d`; raw `pg_dump` restriction tokens were excluded. Restore initially changed the default `PUBLIC` USAGE ACL on `public`; adding that standard grant in the isolated database produced an exact normalized catalog match. Rollback is retained backup plus previous container configuration. | DONE |
| GO-00 | Senior Go Developer | all discovered Go backends | Complete SQL manifest and table-use audit; cover reachable production SQL, DSN/search-path and role switching. Evidence: `UNUSED-TABLES-AUDIT.md`. | DONE |
| DB-01 | Senior DB Engineer | schema | Recorded the two-schema contract, migration ownership, explicit bridge, runtime/group roles, denials, and explicit-grant/default-privilege policy in `SCHEMA-OWNERSHIP-AND-PRIVILEGES.md`; reconciled `docs/srd/03-architecture.md`. | DONE |
| DB-02 | Senior DB Engineer | schema | Adopted `catalog-baseline-2026-10-01` from the checked data-free catalog (`447350…4adb7`) and added the transactional runner. Fresh bootstrap plus dictionary seed and restored-snapshot upgrade converged to identical normalized catalogs (`8beace…4142`). Live adoption marker `9000_catalog_baseline_20261001` is new bookkeeping, not historical replay. | DONE |
| DB-03 | Senior DB Engineer | schema | Applied `0054_default_acl_and_migration_runner` (`2231aa…7aa4`) after isolated rehearsal; it removes only verified broad default grants, retains explicit rights, and adds runner state. Local migration executor can SET ROLE to owner in an isolated transaction; runtime identities cannot create DDL or assume owner. | DONE |
| DB-04 | Senior DB Engineer | schema | Catalog revalidation found no invalid indexes, no unvalidated FKs, no partitions, and no demonstrated query-plan integrity/performance gap requiring DDL. No speculative index or constraint was added. | NOT_APPLICABLE |
| GO-01 | Senior Go Developer | taskgen, grader, cas | All reachable engine SQL is qualified as `public.*`: taskgen `14dba5a`, grader `16aae00`, CAS `b33a11e`. `GOTOOLCHAIN=auto go test ./...` passed in each repository; qualified reads also succeeded under `search_path=pg_catalog`. | DONE |
| GO-02 | Senior Go Developer | platform-api, notifications, payments, auxiliary/auth, auxiliary/kaspi | Reachable PA/NT SQL qualifies platform relations as `mathprep.*` and engine bridge relations as `public.*`; canonical payments has no DB client. Auth is in platform-session mode, so its legacy `mathprep_auth` direct DB path is not reached. The legacy Kaspi repository is not a Compose build context; its standalone schema has no matching live table names. `GOTOOLCHAIN=auto go test ./...` passed there. The bridge and limitations are documented in the audit. | DONE |
| GO-03 | Senior Go Developer | taskgen, grader | Provisioned ignored, mode-0600 local credentials outside Git for `mathprep_taskgen_local` and `mathprep_grader_local`. They inherit only their service group without SET capability; session/current/reset role is the login, not owner. Rebuilt images and explicit `docker run` replacements are healthy. Production secret delivery remains out of scope. | DONE |
| GO-04 | Senior Go Developer | schema, taskgen, grader, cas | Published immutable schema tag `v0.3.11-remediation-20261001` to GitHub after verifying the tag adds the shared locale constants and `GenerationRequest.Locale` contract since v0.3.10. Consumers removed local `replace` directives and pin the exact tag. `go list -m`, tests, and builds pass. | DONE |
| DB-05 | Senior DB Engineer | local Docker runtime | Applied two additive bookkeeping/default-ACL migrations live only after fresh/restored convergence. Taskgen, grader, then Platform API were rebuilt and replaced through explicit `docker run`; renamed stopped containers retain rollback definitions. | DONE |
| GO-05 | Senior Go Developer | taskgen, grader, platform-api | Defined health checks passed after replacement; `pg_stat_activity` confirms dedicated taskgen/grader login identities. Auth, notifications, and payments remained healthy and were not restarted. CAS remains intentionally undeployed. | DONE |
| DB-06 | Senior DB Engineer | schema docs | Final local catalog has `public=33`, `mathprep=96`, ledger=55, zero default ACL entries in target schemas, and matching fresh/restored normalized catalog. Candidate tables remain untouched. Observation-only cleanup is deferred to 2026-10-08. | DONE |
| GO-06 | Senior Go Developer | schema, platform-api, taskgen, grader, cas | Published schema main/tag to GitHub (`5564c7b`, tag points at `30b98e6`). Pushed service pins to GitLab: taskgen `f1dfd48`, grader `40bb9cc`, CAS `0242fd3`. Rebuilt taskgen/grader from the remote module pin and verified healthy. Platform API baseline-readiness commit `5da3ee7` is deployed locally, but this checkout has no remote; adjacent `momentskz/backend-api` is a distinct service and was not treated as its destination. | PENDING |

## Publication and runtime update, 2026-10-01

Schema `main` is pushed to `github/berdsa/mathprep_schema`; immutable tag
`v0.3.11-remediation-20261001` points at commit `30b98e6`. Taskgen, grader,
and CAS now resolve that exact module version with no local `replace` and are
pushed to their configured GitLab `main` branches. The running taskgen/grader
containers were rebuilt from the updated module pins and use their protected
local identities. Platform API is rebuilt and healthy locally, but its current
checkout has no configured Git remote. The nearby `momentskz/backend-api`
repository is an unrelated legacy service with a separate history and was not
used as a guessed destination. To publish Platform API commit `5da3ee7`, its
owner must configure the correct remote or identify the authoritative
GitLab project. Production credentials remain each deployment's secret
manager responsibility.

## Verified migration and role facts

`mathprep.schema_migrations` has 53 rows; it is the only live ledger. `public`
has no migration ledger. The ledger contains a legacy platform stream plus
canonical mappings, including `0053_engine_service_least_privilege`, and the active platform API readiness check validates
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
