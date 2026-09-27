# Billing schema foundation (migration 000098)

This additive migration establishes provider-neutral persistence primitives. It
does not implement checkout, payment capture, refunds, recurring billing, or
entitlement policy. It must not be interpreted as authorization to activate
paid access without an authenticated provider result.

## Records and scope

- `billing_order` records the requesting `actor_principal_id` from
  platform-api's `access_principals.principal_id`, external `tenant_id`,
  tenant/actor idempotency key, KZT amount, and an explicit order state. Actor
  and tenant IDs have no FK because platform-api owns those identity tables and
  the canonical schema has no tenant table.
- `billing_order_child` captures the children and explicit per-child KZT
  allocation selected for one aggregate order. `child_profile_id` is the
  platform-api child-profile ID; it does not map to `students.user_id`. It does
  not calculate pricing, sibling discounts, tax, or fees.
- `payment_attempt` records each provider attempt and its lifecycle, provider
  invoice/payment identifiers, KZT amount, and idempotency key. It stores no
  card data, token, or raw callback secret. `callback_secret_hash_sha256` is
  available only for a one-way digest of a per-attempt callback correlation
  hash such as Halyk `secret_hash`.
- `verified_provider_event` is an idempotency inbox for events that the owning
  adapter has already authenticated. The unique `(provider_code,
  provider_event_id)` pair suppresses replay. Only the SHA-256 digest of the
  exact callback body is retained; no raw callback body or access token is
  stored. An unmatched verified event may have a null attempt reference while
  reconciliation is pending.
- `child_entitlement_period` records per-child paid periods keyed by the same
  platform-api `child_profile_id` as the order allocation.
  Coverage is the explicit half-open interval `[period_starts_at,
  period_ends_at)`. Its insert must be in the same transaction that marks the
  order paid after a verified successful provider result. No trial or default
  duration is represented.

Tenant IDs and platform profile IDs are repeated where needed for composite
foreign keys between billing records; those keys ensure related billing rows
preserve the same scope. The billing schema intentionally has no FK to
`users`/`students`: those IDs are different from platform-api's principals and
child profiles. No guardian role or parent-child relationship is inferred by
these tables.

## Lifecycle and invariants

Orders start `PENDING`, can be marked `PAID` with `paid_at`, or cancelled with
`cancelled_at`. The database checks allowed values and timestamp/state
consistency. Attempts use `CREATED → PENDING → SUCCEEDED|FAILED|CANCELLED` (a
provider status poll may also move `CREATED` directly to a terminal state);
terminal attempts require `completed_at`. These checks validate each row's
state shape but do not enforce transition history. Services must make state
changes transactionally and idempotently, including checking that per-child
allocations sum to the order amount before creating a provider attempt; the
database does not enforce that cross-row sum. Refund, retry scheduling, and
post-payment reversal semantics remain out of scope pending policy.

Order and attempt amounts are explicit positive `NUMERIC(12,2)` KZT values.
The migration does not seed or default a price, discount, tax, fee, term, or
renewal behavior. The UX spec's 500 KZT/month/student is a target only; trial
length, billing-day rules, fees/tax, cancellation, failed-payment access,
refunds, sibling discount percentage/eligibility, and auto-renew policy remain
product decisions (`docs/math-prep-kz-ux-functional-spec.md` §3.7 and Appendix).

## Service and deployment gates

Migration `000103_platform_api_billing_grants` grants the existing
`platform_api_svc` role access to the canonical billing tables. It requires
`platform_api_svc` from migration 000101 and tables from 000098. The API receives
`SELECT, INSERT` on the five billing tables, plus only these column-scoped
updates:

- `billing_order`: `status`, `paid_at`, `updated_at`
- `payment_attempt`: `provider_payment_id`, `status`, `updated_at`,
  `completed_at`
- `verified_provider_event`: `status`, `processed_at`

No UPDATE, DELETE, or TRUNCATE privilege is granted on order allocations or
entitlement periods; paid-period rows are immutable to this role. The grant
migration configures no provider credentials or provider adapter. The API
still must authorize tenant scope, payer/principal access, and child membership
from authoritative MathPrep tables inside the same transaction before
inserting an order or granting an entitlement period. This schema does not
infer role or guardianship. Provider event authenticity, reconciliation, and
an explicit paid-period allocation policy remain service/product gates.

Migration 000103's down migration removes only these billing-table privileges;
it leaves the shared `platform_api_svc` role and grants for other platform
features intact. The migration must be applied before the API's billing
capability preflight can pass.
