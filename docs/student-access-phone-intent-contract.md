# Guardian-provisioned student phone verification contract

Migration `000114_student_access_phone_intent` adds a one-use bridge for setting up sign-in on an already-existing family child profile. It stores no OTP or delivery-provider state. Auth owns the challenge and Redis state; Platform API owns authorization, child/account mutation, and the verified phone row.

## Stored fields and lifecycle

`mathprep.platform_student_access_intent` binds `intent_id` to `child_id`, `tenant_id`, the existing `child_principal_id`, `guardian_relationship_id`, and `guardian_principal_id`. It holds the normalized email, already-hashed password, canonical E.164 phone, and lowercase SHA-256 device-binding digest needed by the finalizer. A trigger requires a `family` tenant and checks the child tenant/principal and learner against the guardian relationship tenant/actor/learner at intent creation. Foreign keys use `ON DELETE RESTRICT`.

Only `pending`, `finalized`, and `expired` are valid states. A pending intent lasts no more than 15 minutes, and only one pending intent may exist per child. The lifecycle trigger permits one transition from pending directly to a terminal status, and requires `email`, `password_hash`, `phone_e164`, and `device_binding` to be nulled in that same update. A finalized intent must complete by expiry; an expired intent is marked at or after expiry. Terminal rows are retained for at least 24 hours after expiry and then removed in bounded batches of 1–500 by the dedicated cleanup function.

## Required request/finalization behavior

1. An authenticated guardian starts the flow for an existing child. Platform API verifies tenant membership, guardian relationship, active account, and applicable consent before creating an intent. The schema trigger checks binding consistency but deliberately does not create or infer consent.
2. Platform API hands the exact intent ID, destination, and device-flow binding to Auth. Auth keeps OTP challenges in Redis, applies attempt/rate limits, sends WhatsApp first with the configured SMS fallback policy, and returns an OTP-success result bound to that same intent/device flow. Parent-entered numbers are never treated as verified.
3. Only after OTP success, Platform API revalidates the family relationship, consent, intent status/expiry/device digest, and email uniqueness. In one DB transaction it updates credentials on the existing `child_principal_id`, inserts that principal's `phone_identity` with verified status and `verified_at`, then marks the intent finalized while scrubbing its secrets. Any conflict rolls back all three writes. It must not create/merge a principal, child, membership, guardian edge, or consent.
4. Failed, mismatched, expired, and replayed challenges do not create a verified phone identity or change credentials. The student's own verified destination is used for new-device sign-in; the guardian phone is never copied to the student.

Auth's OTP proof is an application boundary: this schema does not persist a provider receipt or secret proof token. Platform API must accept only the Auth result for the same opaque intent/device flow, and must make finalization idempotent. Do not use a bare phone-plus-parent-session OTP endpoint, because that could verify the guardian's own identity instead of the child's.

## Database grants

`platform_api_svc` receives SELECT on the intent row, INSERT only for the bound identity and credential input fields, and UPDATE only for terminal state plus secret scrubbing. A transition trigger prohibits edits/reopening. Platform API receives `UPDATE(email)` on `platform_accounts` in addition to the existing `UPDATE(password_hash)` from migration 000113; the application must scope both writes to the child principal bound in the intent. The migration intentionally does not grant the API direct DELETE. The non-login `platform_auth_retention_svc` can SELECT/DELETE only these intents, and Platform API can execute only the bounded `prune_platform_student_access_intents(integer)` function. No auth role or database credentials are given to Auth.

## Rollout prerequisites and known source gap

The migration references the live platform identity tables `access_tenants`, `access_principals`, `access_guardian_relationships`, `platform_children`, and `platform_accounts`. Their relevant keys/columns were confirmed from the running `mathprep` schema snapshot, but their base DDL is not present in the canonical `schema` migration tree. Therefore, before applying 000114, an operator must check the target DB catalog for the referenced IDs and required columns (`platform_children.tenant_id/principal_id/learner_id`; `access_guardian_relationships.tenant_id/guardian_principal_id/learner_id`) and check the migration ledger/checksum sequence. The migration author did not connect to or mutate the live DB. A future schema reconciliation should bring the legacy base DDL and ownership into this repo before claiming fresh-database reproducibility.

Reviewed source checksums:

- Up: `6fcd46cb51856dc05ef4efd8d0d76dcf49a5fa4d8f593f7f4f0378396a3cee91`
- Down: `021f1d96a394330b9b8bf72078ba40fce36502126b4168ec463d474f0670406d`

Rollback refuses while any intent rows remain. Drain/retain those rows according to the 24-hour policy, then run the down migration; it revokes only grants introduced here and does not delete platform identities or consent.
