# Migration-stream manifest

Verified 2026-10-01 against the live `mathprep` PostgreSQL 16.15 database.
This manifest records provenance without fabricating historical application
events or checksums.

| Stream | Objects | Source / bookkeeping | State |
|---|---|---|---|
| Engine | `public.*` task, generation, submission, CAS, journal, and billing relations | `schema/migrations/000001` through `000098` and later engine changes; **no live public ledger exists** | Historical application order cannot be proven from the catalog alone. New cross-cutting remediation is recorded in the existing platform ledger pending a dedicated verified engine runner. |
| Legacy platform baseline | foundational `mathprep.*` access, platform, learning, school, and content relations | live `mathprep.schema_migrations` labels `0002_schema` through `0019_web_push_subscriptions` | Applied records exist, but corresponding full source DDL is absent from the active workspace. Fresh bootstrap is blocked. |
| Canonical platform additions | named `mathprep.*` and bridge grants | `schema/migrations/000099` onward mapped to live ledger labels `0020` onward | Applied values/checksums are verified directly by readiness checks and the ledger. |
| Remediation boundary | role grants only; no object relocation | `schema/migrations/000131_engine_service_least_privilege.up.sql` -> live ledger `0053_engine_service_least_privilege` | Applied 2026-10-01 with SHA-256 `dd866f285d4e1db7e7513837d31d55f168eecd0b91b6c14da90919c6d8bb911d`. |

## Execution ownership

The migration owner is a separate migrator identity (`mathprep_migrator`, a
member of `mathprep_owner`); runtime group roles remain `NOLOGIN` and do not
own objects. Application login identities may `SET ROLE` only to their
respective group where the connection configuration explicitly does so.
[DB] `pg_roles`, `pg_auth_members`, and `pg_db_role_setting` read-only queries
2026-10-01.

## Convergence boundary

An upgrade of the restored live snapshot can apply the verified 000131 grant
migration and preserve table counts, validated FKs, and required grants. A
fresh database cannot yet converge to the current platform catalog because the
legacy platform baseline source is absent. This is a `DB-02` blocker, not a
reason to replay or invent old ledger entries. The required resolution is to
recover the authoritative legacy base migration repository or obtain a
reviewed, reproducible baseline with explicit owner approval.

## Runner contract

Before any subsequent live migration, the runner must:

1. use the migrator identity, not a runtime identity;
2. take an advisory migration lock and set bounded `lock_timeout` and
   `statement_timeout`;
3. preflight the target ledger version/checksum and required catalog objects;
4. apply source and ledger insert atomically; and
5. rerun schema/grant fingerprints before service rollout.

The present workspace has no committed generic runner that implements this
contract. `000131` was applied through an explicit, transaction-bounded
operator session after restored-snapshot rehearsal; that proven procedure is
documented in `REMEDIATION-EXECUTION.md`, but it is not misrepresented as a
reusable runner.
