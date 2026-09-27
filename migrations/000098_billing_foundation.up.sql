-- Provider-neutral billing foundation. Tenant IDs are owned by platform-api,
-- which is not represented in this schema yet; see docs/billing-schema-contract.md.
CREATE TABLE billing_order (
    order_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    -- platform-api access_principals.principal_id; intentionally no FK because
    -- identity records are owned outside this canonical schema.
    actor_principal_id UUID NOT NULL,
    idempotency_key TEXT NOT NULL CHECK (length(btrim(idempotency_key)) > 0),
    currency TEXT NOT NULL DEFAULT 'KZT' CHECK (currency = 'KZT'),
    amount_kzt NUMERIC(12, 2) NOT NULL CHECK (amount_kzt > 0),
    status TEXT NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'PAID', 'CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    paid_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    UNIQUE (tenant_id, actor_principal_id, idempotency_key),
    UNIQUE (order_id, tenant_id),
    CHECK (updated_at >= created_at),
    CHECK (paid_at IS NULL OR paid_at >= created_at),
    CHECK (cancelled_at IS NULL OR cancelled_at >= created_at),
    CHECK (
        (status = 'PENDING' AND paid_at IS NULL AND cancelled_at IS NULL)
        OR (status = 'PAID' AND paid_at IS NOT NULL AND cancelled_at IS NULL)
        OR (status = 'CANCELLED' AND paid_at IS NULL AND cancelled_at IS NOT NULL)
    )
);

-- A parent checkout can cover multiple children. Amounts are explicit per-child
-- allocations; no discount or tax calculation is implied by this table.
CREATE TABLE billing_order_child (
    order_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    -- platform-api platform_children child-profile ID; no fabricated mapping
    -- to schema.students.user_id is assumed.
    child_profile_id UUID NOT NULL,
    amount_kzt NUMERIC(12, 2) NOT NULL CHECK (amount_kzt > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    PRIMARY KEY (order_id, child_profile_id),
    UNIQUE (order_id, tenant_id, child_profile_id),
    FOREIGN KEY (order_id, tenant_id)
        REFERENCES billing_order(order_id, tenant_id) ON DELETE RESTRICT
);

CREATE TABLE payment_attempt (
    payment_attempt_id UUID PRIMARY KEY,
    order_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    provider_code TEXT NOT NULL CHECK (length(btrim(provider_code)) > 0),
    attempt_number INTEGER NOT NULL CHECK (attempt_number > 0),
    idempotency_key TEXT NOT NULL CHECK (length(btrim(idempotency_key)) > 0),
    provider_invoice_id TEXT,
    provider_payment_id TEXT,
    currency TEXT NOT NULL DEFAULT 'KZT' CHECK (currency = 'KZT'),
    amount_kzt NUMERIC(12, 2) NOT NULL CHECK (amount_kzt > 0),
    status TEXT NOT NULL DEFAULT 'CREATED'
        CHECK (status IN ('CREATED', 'PENDING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
    -- For Halyk callback comparison, persist SHA-256(secret_hash), never the
    -- provider's raw per-payment secret_hash.
    callback_secret_hash_sha256 BYTEA
        CHECK (callback_secret_hash_sha256 IS NULL OR octet_length(callback_secret_hash_sha256) = 32),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    completed_at TIMESTAMPTZ,
    UNIQUE (order_id, attempt_number),
    UNIQUE (order_id, idempotency_key),
    FOREIGN KEY (order_id, tenant_id)
        REFERENCES billing_order(order_id, tenant_id) ON DELETE RESTRICT,
    CHECK (updated_at >= created_at),
    CHECK (completed_at IS NULL OR completed_at >= created_at),
    CHECK (
        (status IN ('CREATED', 'PENDING') AND completed_at IS NULL)
        OR (status IN ('SUCCEEDED', 'FAILED', 'CANCELLED') AND completed_at IS NOT NULL)
    )
);

CREATE UNIQUE INDEX payment_attempt_provider_invoice_uq
    ON payment_attempt(provider_code, provider_invoice_id)
    WHERE provider_invoice_id IS NOT NULL;

CREATE UNIQUE INDEX payment_attempt_provider_payment_uq
    ON payment_attempt(provider_code, provider_payment_id)
    WHERE provider_payment_id IS NOT NULL;

-- Rows represent callbacks/events that have already passed provider-specific
-- authenticity checks. Raw callback bodies and access tokens are never stored.
CREATE TABLE verified_provider_event (
    verified_provider_event_id UUID PRIMARY KEY,
    provider_code TEXT NOT NULL CHECK (length(btrim(provider_code)) > 0),
    provider_event_id TEXT NOT NULL CHECK (length(btrim(provider_event_id)) > 0),
    payment_attempt_id UUID REFERENCES payment_attempt(payment_attempt_id) ON DELETE RESTRICT,
    body_sha256 BYTEA NOT NULL CHECK (octet_length(body_sha256) = 32),
    status TEXT NOT NULL DEFAULT 'VERIFIED'
        CHECK (status IN ('VERIFIED', 'APPLIED', 'IGNORED')),
    verified_at TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    processed_at TIMESTAMPTZ,
    UNIQUE (provider_code, provider_event_id),
    CHECK (verified_at <= received_at),
    CHECK (processed_at IS NULL OR processed_at >= received_at),
    CHECK (
        (status = 'VERIFIED' AND processed_at IS NULL)
        OR (status IN ('APPLIED', 'IGNORED') AND processed_at IS NOT NULL)
    )
);

-- Paid coverage periods; access is the explicit half-open interval
-- [period_starts_at, period_ends_at). Refund/cancellation policy is not encoded.
CREATE TABLE child_entitlement_period (
    entitlement_period_id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    child_profile_id UUID NOT NULL,
    order_id UUID NOT NULL,
    period_starts_at TIMESTAMPTZ NOT NULL,
    period_ends_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    FOREIGN KEY (order_id, tenant_id, child_profile_id)
        REFERENCES billing_order_child(order_id, tenant_id, child_profile_id) ON DELETE RESTRICT,
    UNIQUE (order_id, child_profile_id, period_starts_at),
    CHECK (period_ends_at > period_starts_at),
    CHECK (created_at <= period_starts_at)
);

CREATE INDEX billing_order_actor_recent_idx
    ON billing_order(tenant_id, actor_principal_id, created_at DESC);
CREATE INDEX payment_attempt_order_recent_idx
    ON payment_attempt(order_id, created_at DESC);
CREATE INDEX verified_provider_event_attempt_recent_idx
    ON verified_provider_event(payment_attempt_id, received_at DESC)
    WHERE payment_attempt_id IS NOT NULL;
CREATE INDEX child_entitlement_period_child_window_idx
    ON child_entitlement_period(tenant_id, child_profile_id, period_starts_at, period_ends_at);
