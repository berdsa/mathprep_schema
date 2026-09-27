-- platform-api owns provider-attempt correlation as part of its canonical
-- billing lifecycle. Migration 000103 already grants table SELECT plus the
-- provider_payment_id/status/updated_at/completed_at update columns; this
-- migration adds provider invoice ID and digest-only callback-hash persistence.
GRANT SELECT
    ON public.payment_attempt TO platform_api_svc;

GRANT UPDATE (
    provider_invoice_id,
    provider_payment_id,
    callback_secret_hash_sha256,
    status,
    updated_at
) ON public.payment_attempt TO platform_api_svc;

