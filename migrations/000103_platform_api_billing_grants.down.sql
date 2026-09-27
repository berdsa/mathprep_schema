-- Remove only the billing capabilities added by migration 000103.
REVOKE SELECT, INSERT
    ON public.billing_order, public.billing_order_child, public.payment_attempt,
       public.verified_provider_event, public.child_entitlement_period
    FROM platform_api_svc;

REVOKE UPDATE (status, paid_at, updated_at)
    ON public.billing_order FROM platform_api_svc;

REVOKE UPDATE (provider_payment_id, status, updated_at, completed_at)
    ON public.payment_attempt FROM platform_api_svc;

REVOKE UPDATE (status, processed_at)
    ON public.verified_provider_event FROM platform_api_svc;

