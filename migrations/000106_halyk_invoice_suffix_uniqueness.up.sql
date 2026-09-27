-- Halyk ePay requires invoice IDs to remain unique by their last six
-- characters, even when the full merchant invoice IDs differ.
CREATE UNIQUE INDEX payment_attempt_halyk_invoice_suffix6_uq
    ON public.payment_attempt (right(provider_invoice_id, 6))
    WHERE provider_code = 'halyk_epay'
      AND provider_invoice_id IS NOT NULL;

