# Migration-stream manifest

Verified 2026-10-01 against the live `mathprep` PostgreSQL 16.15 database.
This manifest records provenance without fabricating historical application
events or checksums.

| Stream | Objects | Source / bookkeeping | State |
|---|---|---|---|
| Engine | `public.*` task, generation, submission, CAS, journal, and billing relations | `schema/migrations/000001` through `000098` and later engine changes; **no live public ledger exists** | Historical application order cannot be proven from the catalog alone. New cross-cutting remediation is recorded in the existing platform ledger pending a dedicated verified engine runner. |
| Catalog-derived baseline | all `public`/`mathprep` definitions as captured 2026-10-01 | `bootstrap/2026-10-01/catalog.sql`, marker `9000_catalog_baseline_20261001` | New reconstruction for fresh installs and existing adoption; never a claim that legacy source was recovered. |
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

The live catalog is nevertheless reproducibly captured as the data-free
`LIVE-CATALOG-DDL-2026-10-01.sql` baseline (SHA-256
`0b370703691dfa820053f770b09619f186c47f40e3e78c8a00eb6898a7526209`). It
supports provenance review and drift detection; it must not be replayed as a
historical migration against an existing database.

## Runner contract

Before any subsequent live migration, the runner must:

1. use the migrator identity, not a runtime identity;
2. take an advisory migration lock and set bounded `lock_timeout` and
   `statement_timeout`;
3. preflight the target ledger version/checksum and required catalog objects;
4. apply source and ledger insert atomically; and
5. rerun schema/grant fingerprints before service rollout.

`scripts/dbmigrate.sh` now implements this contract for transactional SQL:
advisory lock, bounded timeouts, source checksum verification, runner state,
and atomic ledger write. Nontransactional migrations must be split and handled
explicitly; none is in this remediation.

## Follow-up resolution path, 2026-10-01

Only `0019_web_push_subscriptions.sql` was found in the archived monolith's
migration directory; historical recovery remains partial. If full recovery
fails, adopt a new catalog-derived baseline for clean installs and a
fingerprint-checked adoption marker for existing databases. Preserve old
ledger records and avoid replaying already embodied migrations. This is
proposed work, not a completed bootstrap. The declared migrator currently
lacks schema CREATE and ledger INSERT rights. [DB][CODE]
See `UNBLOCK-AND-COMPLETE-PROMPT.md` for executable resolution steps.
