REVOKE SELECT (student_id, domain, tier, ema_score, updated_at)
    ON public.mastery_topic FROM platform_api_svc;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mathprep_platform_local') THEN
        REVOKE SELECT (student_id, domain, tier, ema_score, updated_at)
            ON public.mastery_topic FROM mathprep_platform_local;
    END IF;
END $$;
