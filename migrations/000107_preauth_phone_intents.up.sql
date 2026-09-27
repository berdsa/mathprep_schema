-- Durable, one-use state for pre-auth registration and student device step-up.
-- OTP challenges and browser sessions remain owned by Auth/Redis; Auth receives
-- no database credentials. The platform API consumes these intents atomically.
CREATE TABLE mathprep.platform_registration_intent (
    intent_id UUID PRIMARY KEY,
    email TEXT NOT NULL CHECK (email = lower(email)),
    password_hash TEXT NOT NULL CHECK (length(password_hash) BETWEEN 1 AND 1024),
    display_name TEXT NOT NULL CHECK (length(btrim(display_name)) BETWEEN 1 AND 200),
    locale TEXT NOT NULL CHECK (length(locale) BETWEEN 2 AND 16),
    requested_role TEXT NOT NULL CHECK (requested_role IN ('family_owner', 'student')),
    phone_e164 TEXT NOT NULL CHECK (phone_e164 ~ '^\+[1-9][0-9]{1,14}$'),
    terms_version TEXT NOT NULL CHECK (length(terms_version) BETWEEN 1 AND 64),
    -- Records the user's affirmative acknowledgement, not a guardian/legal claim.
    terms_acknowledged_at TIMESTAMPTZ NOT NULL,
    device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'finalized', 'expired')),
    finalized_principal_id UUID REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    finalized_at TIMESTAMPTZ,
    CHECK (expires_at > created_at),
    CHECK (
        (status = 'pending' AND finalized_principal_id IS NULL AND finalized_at IS NULL)
        OR (status = 'finalized' AND finalized_principal_id IS NOT NULL AND finalized_at IS NOT NULL)
        OR (status = 'expired' AND finalized_principal_id IS NULL AND finalized_at IS NULL)
    ),
    CHECK (finalized_at IS NULL OR finalized_at >= created_at)
);

CREATE INDEX platform_registration_intent_pending_expiry_idx
    ON mathprep.platform_registration_intent(expires_at)
    WHERE status = 'pending';
CREATE INDEX platform_registration_intent_pending_phone_idx
    ON mathprep.platform_registration_intent(phone_e164, expires_at)
    WHERE status = 'pending';

CREATE TABLE mathprep.platform_login_intent (
    intent_id UUID PRIMARY KEY,
    principal_id UUID NOT NULL
        REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    membership_id UUID NOT NULL
        REFERENCES mathprep.access_memberships(id) ON DELETE RESTRICT,
    phone_identity_id UUID NOT NULL
        REFERENCES mathprep.phone_identity(phone_identity_id) ON DELETE RESTRICT,
    device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$'),
    device_token_digest TEXT CHECK (device_token_digest IS NULL OR device_token_digest ~ '^[0-9a-f]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'completed', 'expired')),
    CHECK (expires_at > created_at)
);

CREATE INDEX platform_login_intent_pending_expiry_idx
    ON mathprep.platform_login_intent(expires_at)
    WHERE status = 'pending';
CREATE INDEX platform_login_intent_pending_principal_idx
    ON mathprep.platform_login_intent(principal_id, expires_at)
    WHERE status = 'pending';

CREATE TABLE mathprep.platform_trusted_device (
    trusted_device_id UUID PRIMARY KEY,
    principal_id UUID NOT NULL
        REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    token_digest TEXT NOT NULL UNIQUE CHECK (token_digest ~ '^[0-9a-f]{64}$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    CHECK (expires_at > created_at),
    CHECK (last_seen_at >= created_at),
    CHECK (revoked_at IS NULL OR revoked_at >= created_at)
);

CREATE INDEX platform_trusted_device_principal_active_idx
    ON mathprep.platform_trusted_device(principal_id, expires_at)
    WHERE revoked_at IS NULL;

-- platform_api_svc already exists and has schema USAGE from prior migrations.
-- The role can read the intent data it must validate, create intent rows, and
-- advance lifecycle/token fields only. It cannot delete or truncate records.
GRANT SELECT ON mathprep.platform_registration_intent TO platform_api_svc;
GRANT INSERT (
    intent_id, email, password_hash, display_name, locale, requested_role,
    phone_e164, terms_version, terms_acknowledged_at, device_binding, expires_at
) ON mathprep.platform_registration_intent TO platform_api_svc;
GRANT UPDATE (status, finalized_principal_id, finalized_at)
    ON mathprep.platform_registration_intent TO platform_api_svc;

GRANT SELECT ON mathprep.platform_login_intent TO platform_api_svc;
GRANT INSERT (
    intent_id, principal_id, membership_id, phone_identity_id,
    device_binding, device_token_digest, expires_at
) ON mathprep.platform_login_intent TO platform_api_svc;
GRANT UPDATE (device_token_digest, status)
    ON mathprep.platform_login_intent TO platform_api_svc;

GRANT SELECT ON mathprep.platform_trusted_device TO platform_api_svc;
GRANT INSERT (
    trusted_device_id, principal_id, token_digest, expires_at
) ON mathprep.platform_trusted_device TO platform_api_svc;
GRANT UPDATE (last_seen_at, expires_at, revoked_at)
    ON mathprep.platform_trusted_device TO platform_api_svc;

-- Only Auth-gated, atomic registration finalization may insert an already
-- verified number. Auth proves the OTP; the platform API owns the identity row.
GRANT INSERT (verified_at)
    ON mathprep.phone_identity TO platform_api_svc;
