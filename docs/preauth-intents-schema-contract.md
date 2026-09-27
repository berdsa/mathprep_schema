# Pre-auth intent schema contract

Migration `000107_preauth_phone_intents` stores short-lived pre-auth registration and student login intent state in `mathprep`, plus digest-only trusted-device records. Auth owns OTP and Redis; it has no database role or credentials. The platform API validates and finalizes intent state.

Registration intents record the canonical terms version and `terms_acknowledged_at`. Auth must require an affirmative terms checkbox before creating an intent; the platform API persists the accepted version and timestamp. This is evidence of the user's acknowledgement of the applicable terms only. It does not assert legal guardianship, age, identity, or authority over another person's learner account.

Both registration and login intents bind to a pre-auth flow using a required lowercase SHA-256 hex digest. The schema stores no raw flow cookie, OTP, or trusted-device cookie. Trusted devices store only a unique lowercase SHA-256 hex token digest.

`platform_api_svc` receives SELECT, restricted-column INSERT, and lifecycle-only UPDATE privileges on the three tables. It receives no DELETE or TRUNCATE privilege. The down migration first refuses to proceed while any intent or device rows remain, then revokes only privileges introduced by this migration and drops the empty tables.

The migration contract test checks required columns and constraints, the timestamp's restricted INSERT privilege and matching rollback REVOKE, role boundaries, and non-destructive rollback ordering. Per the implementation request, PostgreSQL runtime application/rollback validation is intentionally not performed here.
