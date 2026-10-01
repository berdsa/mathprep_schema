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
| DB-01 | Senior DB Engineer | schema | Record public-engine/mathprep-platform ownership, explicit bridge and privilege matrix; reconcile canonical architecture text. Rollback is documentation-only. | PENDING |
| DB-02 | Senior DB Engineer | schema | Add only a new, reproducible stream-manifest/baseline migration after restore rehearsal; never fabricate old application records. Fresh and restored-upgrade catalogs must converge. | BLOCKED — base platform creation DDL is absent from canonical source, documented in `deploy/local/docs/platform-schema-source-gaps.md:1-45`; a baseline can be recorded but clean bootstrap cannot yet be proven. |
| DB-03 | Senior DB Engineer | schema | Add grants before consumer switch; prove positive/negative column grants, no grader write to frozen answers, and insert-only journals. Revoke only newly added grants on rollback. | PENDING |
| DB-04 | Senior DB Engineer | schema | Add only catalog-proven index/constraint gaps with bounded lock/statement timeouts; rehearse on restored DB. | PENDING — requires DB-00/02 and exact manifest. |
| GO-01 | Senior Go Developer | taskgen, grader, cas | Taskgen is complete: all reachable engine SQL is qualified and `GOTOOLCHAIN=auto go test ./...` passed; commit `14dba5a`. Grader and CAS remain to be qualified and tested under a hostile search path. | PENDING |
| GO-02 | Senior Go Developer | platform-api, notifications, payments, auxiliary/auth | Verify all platform SQL is `mathprep.*`; document public bridge; do not change Auth without verified target schema. | PENDING |
| GO-03 | Senior Go Developer | each active service | Wire only verified login identities and startup privilege probes; no DSNs in source/logs. | PENDING — depends on DB-03. |
| GO-04 | Senior Go Developer | schema + consumers | Validate module/remote/release layout; create a new immutable tag only after a shared-module change and tests; update consumers to exact tag. | BLOCKED — no shared-module change is justified by current remediation and publication authority is not established. |
| DB-05 | Senior DB Engineer | schema / deploy runbook | Bounded writer freeze only if needed, service-by-service readiness, pre/post checks, explicit previous-image/config recovery. | PENDING — cannot claim live cutover before DB-00 through DB-04. |
| GO-05 | Senior Go Developer | active services | Isolated synthetic regression matrix and independent service cutover verification. | PENDING — depends on DB-05 and Go tasks. |
| DB-06 | Senior DB Engineer | schema docs | Re-query final catalog, update DB documentation, retain candidates; remove compatibility grants only after observation gate. | PENDING |
| GO-06 | Senior Go Developer | each changed service | Run changed-package tests/vet/build; commit only task-owned files per repository. | PENDING |

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
