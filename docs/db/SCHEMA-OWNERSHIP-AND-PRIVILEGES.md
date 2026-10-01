# Schema ownership and runtime-privilege contract

Verified against the live database on 2026-10-01. This contract is the
authorized two-schema target; it does not move or remove data.

## Ownership and migration contract

| Scope | Owner / authority | Contract |
|---|---|---|
| `public` schema | `pg_database_owner`; engine relations owned by `mathprep` | Engine schema: task catalogue, generation, frozen assignments, submissions/mastery, CAS queue, journals, and billing bridge. Engine SQL is always `public.*`. |
| `mathprep` schema | `mathprep`; platform relations owned by `mathprep` | Platform schema: identity, tenancy, school, learning, inbox/outbox, and platform operations. Platform SQL is always `mathprep.*`. |
| Migration authority | `mathprep_migrator`, member of `mathprep_owner` | Only the migrator applies DDL/grants and writes a proved applied ledger record atomically. Runtime identities do not own objects. |
| Public historical stream | schema migration files | No applied public ledger was found. Never synthesize historical records. |
| Platform stream | `mathprep.schema_migrations` | Legacy baseline labels plus verified canonical additions; see `MIGRATION-STREAM-MANIFEST.md`. |

Explicit reviewed grants remain the target policy. A subsequent read-only
check found three default ACL entries: `mathprep_owner/mathprep` grants table
rights to `mathprep_app`; `mathprep/public` grants broad future table and
sequence rights to taskgen/grader. The previous absence claim was incorrect.
Reconciliation is pending. [DB] See `BLOCKERS-AND-AUXILIARY-SERVICES.md`.

For local development, `mathprep_local_migrator` is a non-runtime LOGIN role
with only controlled SET membership in owner `mathprep`; this is required for
owner-held DDL and is verified only in isolated transactions. Runtime roles
have neither this membership nor DDL authority. Broad default ACLs were
removed by `0054_default_acl_and_migration_runner`; explicit grants remain.

## Runtime identity model

| Group role | Login? | Schema access | Allowed engine/platform operations |
|---|---:|---|---|
| `taskgen_svc` | no | `public` USAGE | generation request R/I/U; task set and instance R/I; task type R/I/U; template/student R; event journal I only. |
| `grader_svc` | no | `public` USAGE | catalogue/assignment R; submission R/I; mastery R/I/U; CAS request/receipt R/I; event journal I only. No task-instance or billing mutation. |
| `cas_svc` | no | `public` USAGE | CAS queue R/I plus existing lifecycle-column U; event journal I only. |
| `platform_api_svc` | no | `mathprep`, `public` USAGE | column-scoped platform/bridge grants proven by platform readiness; no blanket table grant is assumed. |
| `mathprep_notifications_svc` | yes, local | `mathprep` USAGE | notification/outbox and limited account-locale access only. |
| `platform_auth_retention_svc` | no | `mathprep` USAGE | bounded retention functions and their explicit retention tables only. |

Local `mathprep_platform_local` is a platform API login member of
`platform_api_svc`. The current taskgen/grader deployment authenticates as
the owner and sets a group role through connection options; this is temporarily
restricted by the group grants but is **not** a final least-privilege login
boundary because the owner can reset the role. GO-03 remains blocked until
dedicated non-owner login credentials can be provisioned through the approved
secret-distribution path.

## Mandatory denials

* Grader has no `UPDATE`/`DELETE` on `public.task_instance` and cannot change
  frozen answers.
* Taskgen and grader have no table privileges on public billing relations.
* Taskgen, grader, and CAS have `INSERT` only on `public.event_log`; no
  update/delete permission is granted.
* Runtime roles have no migration ownership authority and no implicit
  cross-schema access.

`000131_engine_service_least_privilege` implements the engine slice and is
recorded as live ledger `0053_engine_service_least_privilege`. Isolated
positive and negative privilege probes are documented in
`REMEDIATION-EXECUTION.md`. [MIGRATION]
`migrations/000131_engine_service_least_privilege.up.sql`; [DB] post-apply
`has_table_privilege`/`has_column_privilege` checks.
