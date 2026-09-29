REVOKE SELECT (evidence_count)
    ON public.mastery_topic FROM platform_api_svc;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mathprep_platform_local') THEN
        REVOKE SELECT (evidence_count)
            ON public.mastery_topic FROM mathprep_platform_local;
    END IF;
END $$;

DROP TRIGGER mastery_topic_evidence_count_write ON public.mastery_topic;
DROP FUNCTION public.set_mastery_topic_evidence_count();

ALTER TABLE public.mastery_topic
    DROP COLUMN evidence_count;
