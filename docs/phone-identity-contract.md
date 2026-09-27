# Verified phone identity contract

Migration `000100_verified_phone_identity` stores one current phone destination
for a platform access principal. `mathprep.access_principals` remains owned by
`platform-api`; this migration depends on that table existing and adds no
`users` or `students` mapping. It is applied only after the platform identity
schema is present.

## Table and lifecycle

`mathprep.phone_identity` contains:

| Column | Contract |
|---|---|
| `phone_identity_id` | Caller-generated UUID primary key. |
| `principal_id` | Required FK to `mathprep.access_principals(id)`, delete restricted. |
| `phone_e164` | Canonical E.164 text, constrained to `+` followed by 2–15 digits, first digit nonzero. |
| `status` | `pending`, `verified`, or `revoked`; defaults to `pending`. |
| `created_at` | Database transaction timestamp when the association was created. |
| `verified_at` | Nullable; set when OTP verification succeeds. Never set at pending creation. |
| `revoked_at` | Nullable; set when the association is revoked or a pending attempt is cancelled. |

The lifecycle is `pending → verified → revoked`, or `pending → revoked` when
verification is abandoned. Constraints keep status and timestamps consistent.
Revocation is terminal; create a new row for a later phone change or a number
that has been recycled. Do not update a revoked row back to pending or verified.

There is at most one non-revoked phone row per principal, so an existing
account can link or replace a number without introducing ambiguous fallback
destinations. There is at most one current verified row per E.164 number across
all principals. A pending number is not reserved globally; the unique verified
index resolves concurrent verification attempts by allowing only one to win.
The exact login lookup is `WHERE phone_e164 = $1 AND status = 'verified'`.
Pending and revoked rows must never authenticate, resolve a principal, or
trigger account creation. Consumers should treat no row as no phone login.

## Enrollment and account linking

For an existing parent or student principal, require an authenticated session
and the applicable account-control checks before inserting a pending row. Send
the OTP only to the submitted canonical number. On successful OTP verification,
update that row to `verified` and set `verified_at` in the same transaction as
the verification result is accepted. Failed, expired, or replayed codes do not
change the phone row to verified. Revoke the old row before starting a phone
replacement; keep its timestamps for audit.

For a student using a new device, the verified phone resolves only to that
student's own principal. A parent's number must not be copied to a child
principal or used as proof of the child's identity. Parent access to a child
continues through the platform's guardian relationship and consent checks.
If a student has no independently controlled number, this schema does not
define the alternate recovery or parent-assisted authentication flow.

No OTP, OTP hash, SMS body, delivery-provider response, or access token belongs
in this table. OTP issue/expiry/attempt limits and rate limiting remain an
application-layer responsibility. Never log the phone number or include it in
`EVENT_LOG`/audit payloads. The E.164 value is personal data: restrict table
access to the identity service, redact it from diagnostics, and apply the
project's retention/deletion policy. The database uniqueness index necessarily
contains the value; this migration does not provide encryption at rest beyond
the database's storage controls.

## Platform API grants

Migration `000104_platform_api_phone_identity_grants` grants the existing
`platform_api_svc` role narrowly scoped access to `mathprep.phone_identity`.
It depends on the table from 000100, role from 000101, and `mathprep` schema
USAGE granted by 000102. SELECT is limited to `phone_identity_id`,
`principal_id`, `phone_e164`, and `status`: these columns support owner-scoped
state lookup, matching the pending number, returning only a server-masked
suffix, and selecting the row for lifecycle changes. In particular,
`phone_e164` remains sensitive even though the API response masks it; the
service must never expose or log the full value.

INSERT is limited to `phone_identity_id`, `principal_id`, `phone_e164`, and
`status`. UPDATE is limited to `status`, `verified_at`, and `revoked_at`.
`created_at` is database-defaulted and immutable through this role. No DELETE,
TRUNCATE, or privilege on OTP or delivery data is granted. The down migration
revokes only these column grants and leaves the shared role and schema USAGE
intact.

## Rollback

The up migration only adds the table and indexes. The down migration refuses
to drop the table while any identity history exists. Before rollback, operators
must deliberately export/archive the rows under the applicable retention
controls; after the table is empty, the down migration removes it. It never
cascades to or deletes access principals.
