# Platform `assessment_ready` inbox and push contract

Migration `000123_platform_assessment_ready` extends the currently deployed
MathPrep platform inbox/outbox schema with an `assessment_ready` event. It is an
additive compatibility extension, not creation DDL for
`platform_notifications` or `platform_learning_sessions`.

## Recovered-live-baseline caveat

The original creation migrations for `mathprep.platform_notifications` and
`mathprep.platform_learning_sessions` are absent from the canonical migration
tree. Before making this extension, the existing `mathprep` database was
inspected read-only. The reviewed baseline includes the named placement-kind,
join-request reference, class, recipient/tenant/kind/reference uniqueness,
test-session, and push-outbox constraints used by migration 000123. The
migration checks for those relations, columns, key constraints, and the
existing outbox identity index and aborts if they are absent or incompatible.

This does not recover the historical source migration, certify every property
of the deployed base schema, or make an empty database bootstrappable from the
canonical migration chain. Clean bootstrap remains an independent schema
reconciliation task. Do not apply the migration to a database whose baseline
has not been inspected and matched to its preconditions.

## Typed inbox references and deduplication

Existing placement events retain their required `reference_id` foreign key to
`platform_join_requests`; `class_id` remains required and foreign-keyed to
`platform_classes`. Assessment events have `reference_id IS NULL` and a
non-null `session_id` foreign-keyed to `platform_learning_sessions(id)`. A
check constraint makes these two reference shapes exclusive. Thus the original
reference relationship is preserved instead of weakening it into a
polymorphic identifier.

An assessment inbox row is unique per `(recipient_principal_id, tenant_id,
session_id)`. The push outbox continues to identify a notification row by its
existing exact `(notification_id, recipient_principal_id, event_kind)` foreign
key; `assessment_ready` is added to the allowed event kinds. The producer must
insert the inbox and outbox rows in the same transaction and enqueue only when
the inbox insert returns a newly created ID.

The Platform API may insert the new `session_id` column; this migration grants
only `INSERT(session_id)` to `platform_api_svc`. It grants no inbox reads,
updates, deletes, or broader outbox access. Existing table/column permissions
remain as they were before the migration.

## Producer and recipient boundary

The platform API producer is a separate service change. It must emit only when
a `mode='test'` session makes its persisted transition to `status='finished'`
after grading succeeds. It must not emit for practice, diagnostics, failed or
still-finalizing sessions, nor on replay of an already-finished session. The
session lock and unique session-recipient key jointly provide transition
serialization and retry idempotency.

At transition time, recipients are limited to active teachers assigned to the
test class and active school administrators in the owning tenant, with an
active placed child, active membership, principal, and tenant. Student and
guardian recipients are outside this event contract. Inbox list and read
authorization must verify the same current tenant, class assignment/admin, and
active placement boundary. Push content stays generic and routes to the
authenticated inbox item; assessment details are loaded only by the authorized
inbox/session API.

## Rollback

The down migration refuses to proceed while any assessment inbox or outbox row
exists. Operators must deliberately archive/remove those rows first. It then
removes the new grants, constraints, index, and typed column and restores the
original three-kind checks and `reference_id NOT NULL` state. It does not drop
or recreate the pre-existing base tables or foreign keys.
