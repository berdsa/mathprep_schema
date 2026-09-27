-- Least-privilege billing capabilities for platform-api reconciliation.
-- platform_api_svc is created by migration 000101. Keep this additive grant
-- boundary separate from the provider-neutral tables introduced in 000098.
REVOKE ALL PRIVILEGES ON
    public.billing_order,
    public.billing_order_child,
    public.payment_attempt,
    public.verified_provider_event,
    public.child_entitlement_period
    FROM platform_api_svc;

GRANT SELECT, INSERT
    ON public.billing_order, public.billing_order_child, public.payment_attempt,
       public.verified_provider_event, public.child_entitlement_period
    TO platform_api_svc;

-- The API mutates only these columns. Column UPDATE privileges also satisfy
-- its SELECT ... FOR UPDATE authorization when paired with SELECT above.
GRANT UPDATE (status, paid_at, updated_at)
    ON public.billing_order TO platform_api_svc;

GRANT UPDATE (provider_payment_id, status, updated_at, completed_at)
    ON public.payment_attempt TO platform_api_svc;

GRANT UPDATE (status, processed_at)
    ON public.verified_provider_event TO platform_api_svc;
