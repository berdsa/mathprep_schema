-- Phone identities belong to platform principals.  Keep the phone value in
-- one restricted table, and retain revoked rows as an audit history.
CREATE TABLE mathprep.phone_identity (
    phone_identity_id UUID PRIMARY KEY,
    principal_id UUID NOT NULL
        REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    phone_e164 TEXT NOT NULL
        CHECK (phone_e164 ~ '^\+[1-9][0-9]{1,14}$'),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'verified', 'revoked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    verified_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    CHECK (verified_at IS NULL OR verified_at >= created_at),
    CHECK (revoked_at IS NULL OR revoked_at >= created_at),
    CHECK (
        (status = 'pending' AND verified_at IS NULL AND revoked_at IS NULL)
        OR (status = 'verified' AND verified_at IS NOT NULL AND revoked_at IS NULL)
        OR (status = 'revoked' AND revoked_at IS NOT NULL)
    )
);

-- At most one current destination per principal.  A phone change revokes the
-- previous row before inserting its replacement; revoked rows remain intact.
CREATE UNIQUE INDEX phone_identity_one_current_per_principal_uq
    ON mathprep.phone_identity(principal_id)
    WHERE status IN ('pending', 'verified');

-- Only verified identities participate in login lookup.  The partial unique
-- index makes that lookup resolve to at most one principal, including when
-- multiple verifications race.
CREATE UNIQUE INDEX phone_identity_verified_phone_uq
    ON mathprep.phone_identity(phone_e164)
    WHERE status = 'verified';

CREATE INDEX phone_identity_principal_history_idx
    ON mathprep.phone_identity(principal_id, created_at DESC);
