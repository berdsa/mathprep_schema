-- Only these two UPDATE columns are new relative to 000103. Do not
-- revoke provider_payment_id/status/updated_at/completed_at: the earlier
-- billing grant migration owns those capabilities and terminal reconciliation.
REVOKE UPDATE (provider_invoice_id, callback_secret_hash_sha256)
    ON public.payment_attempt FROM platform_api_svc;

