# Platform push outbox contract

Migration `000102_platform_push_outbox` adds a durable PostgreSQL handoff from
the platform API's inbox writer to the independent `notifications` service.
The existing inbox remains the user-visible source of truth; the outbox stores
only the inbox notification UUID, recipient principal UUID, event kind, and
delivery bookkeeping. It contains no rendered message, child/student details,
OTP, phone number, provider payload, or subscription secret.

## Transactional producer contract

When the platform API creates an inbox notification, it inserts the matching
`mathprep.platform_push_outbox` row in the same database transaction. It must
use the ID returned by the successful inbox `INSERT ... RETURNING id`, and
enqueue only when that insert created a row. The outbox primary key is the
inbox notification ID, so retries or duplicate enqueue attempts are
idempotent. The composite foreign key prevents dispatch for a missing inbox
row and requires `recipient_principal_id` and `event_kind` to match that exact
row. A unique index on `(id, recipient_principal_id, kind)` supports this
constraint. Supported event kinds currently match the platform inbox kinds:
`join_requested`, `join_approved`, and `join_declined`.

`platform_api_svc` may insert only `notification_id`,
`recipient_principal_id`, and `event_kind`. It cannot read, update, or delete
outbox rows. Deployment-specific logins inherit this group role; this migration
does not grant to a deployment login.

## Claim, lease, retry, and delivery

`mathprep_notifications_svc` has `SELECT` and column-scoped `UPDATE` on the
outbox. It cannot enqueue or delete events and cannot change the event identity
or recipient. Claim due `pending` rows and expired `in_progress` leases in a
short transaction using `FOR UPDATE SKIP LOCKED`; atomically set
`status='in_progress'`, a fresh random `lease_token`, `lease_expires_at`,
increment `attempt_count`, and update `updated_at`. Commit before making the
network request. A worker may complete or fail an event only when its update
matches both `notification_id` and its current `lease_token`.

Use a two-minute initial lease and extend it only while actively delivering.
After a transient failure, clear the lease, return the row to `pending`, set
`next_attempt_at` with exponential backoff plus jitter (starting at 5 seconds,
capped at 1 hour), and store only one of the constrained `last_error_class`
values. Do not store provider response bodies or endpoint/token data in error
fields or logs. After ten claimed attempts, mark the row `dead`; a crashed
worker's expired tenth lease is also terminally marked dead by the next
reclaimer. A permanent error or an invalid/revoked subscription can be marked
dead immediately. On success, set `status='delivered'`, `delivered_at`, clear
the lease, and update `updated_at`.

The database gives at-most-one durable event per inbox notification, while the
external Web Push send is at-least-once across crashes: a relay may accept a
send just before a worker loses its lease. Use `notification_id` as the stable
delivery idempotency key wherever the relay/client path supports deduplication.
The push body must be generic (for example, “You have a new MathPrep
notification”) and link to the authenticated inbox item by ID; render any
details only after the client loads the authorized inbox view.

Delivered and dead rows may be purged after 30 days by a separately operated
retention task. Do not delete pending or leased rows as part of routine cleanup.
If retention is not yet deployed, rows remain durable and cleanup is simply
deferred.

The down migration refuses to drop the table while any delivery rows remain.
Operators must drain/archive the queue and remove retained rows deliberately
before rolling back the schema. It removes the composite inbox index after the
outbox table. It leaves `USAGE` on schema `mathprep` granted to
`platform_api_svc`: schema visibility alone does not grant table access, and
revoking this namespace privilege during rollback could break other platform
objects added later.

## Required integration work

The platform API's current inbox insert path must capture `RETURNING id` and
insert the outbox row only for a newly created inbox row, inside the same
transaction. The notifications service must replace any immediate-only event
delivery path with this queue consumer, using its existing
`mathprep_notifications_svc` database connection. Deployments must provision
that role and grant `platform_api_svc` membership to the platform API login as
they already do for platform identity writes. Apply the schema migration only
after `mathprep.platform_notifications` exists.
