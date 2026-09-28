-- Platform API returns a learner's existing mastery estimate to that learner
-- or an explicitly authorized family. Keep this read limited to the columns
-- used by the endpoint.
GRANT SELECT (student_id, domain, tier, ema_score, updated_at)
    ON public.mastery_topic TO platform_api_svc;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mathprep_platform_local') THEN
        GRANT SELECT (student_id, domain, tier, ema_score, updated_at)
            ON public.mastery_topic TO mathprep_platform_local;
    END IF;
END $$;
