-- After OTP-verified registration, the authoritative account and phone
-- identity have been created. Remove duplicate credentials/contact data from
-- the one-use intent while retaining its role, locale, acknowledgement
-- metadata, finalization link, and bounded-retention lifecycle.
GRANT UPDATE (email, password_hash, display_name, phone_e164, device_binding)
    ON mathprep.platform_registration_intent TO platform_api_svc;
