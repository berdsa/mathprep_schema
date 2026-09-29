-- Preserve the number of parseable graded responses that contributed to the
-- current mastery EMA. Grader writes mastery_topic and its MASTERY_UPDATED
-- event in one transaction; this trigger keeps the count aligned without
-- granting the grader direct control over the evidence_count value.
-- Execute this migration as one transaction so both validation locks remain
-- held through the backfill and the trigger becomes active atomically.

-- Match grader's write order (mastery_topic, then event_log) while preventing
-- either table from changing between validation and the backfill.
LOCK TABLE public.mastery_topic IN ACCESS EXCLUSIVE MODE;
LOCK TABLE public.event_log IN SHARE MODE;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.event_log e
        WHERE e.event_type = 'MASTERY_UPDATED'
          AND (
              e.payload_json->>'student_id' IS NULL
              OR e.payload_json->>'domain' IS NULL
              OR e.payload_json->>'tier' IS NULL
              OR e.payload_json->>'score' IS NULL
              OR (e.payload_json->>'score') !~ '^(0(\.0*)?|1(\.0*)?)$'
          )
    ) THEN
        RAISE EXCEPTION 'cannot backfill mastery evidence_count: malformed MASTERY_UPDATED event';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.event_log e
        WHERE e.event_type = 'MASTERY_UPDATED'
          AND NOT EXISTS (
              SELECT 1
              FROM public.mastery_topic m
              WHERE m.student_id = (e.payload_json->>'student_id')::uuid
                AND m.domain = e.payload_json->>'domain'
                AND m.tier = e.payload_json->>'tier'
          )
    ) THEN
        RAISE EXCEPTION 'cannot backfill mastery evidence_count: MASTERY_UPDATED event has no current mastery row';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.mastery_topic m
        WHERE NOT EXISTS (
            SELECT 1
            FROM public.event_log e
            WHERE e.event_type = 'MASTERY_UPDATED'
              AND (e.payload_json->>'student_id')::uuid = m.student_id
              AND e.payload_json->>'domain' = m.domain
              AND e.payload_json->>'tier' = m.tier
        )
    ) THEN
        RAISE EXCEPTION 'cannot backfill mastery evidence_count: current mastery row has no source event';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.mastery_topic m
        JOIN (
            SELECT (e.payload_json->>'student_id')::uuid AS student_id,
                   e.payload_json->>'domain' AS domain,
                   e.payload_json->>'tier' AS tier,
                   MAX(e.occurred_at) AS last_event_at
            FROM public.event_log e
            WHERE e.event_type = 'MASTERY_UPDATED'
            GROUP BY 1, 2, 3
        ) s USING (student_id, domain, tier)
        WHERE s.last_event_at IS DISTINCT FROM m.updated_at
    ) THEN
        RAISE EXCEPTION 'cannot backfill mastery evidence_count: last source-event timestamp disagrees with mastery.updated_at';
    END IF;

    -- Verify the current EMA using the same 0.8/0.2 update rule and stable
    -- event ordering used by the audit: occurred_at, then event_id.
    IF EXISTS (
        WITH RECURSIVE ordered_events AS (
            SELECT (e.payload_json->>'student_id')::uuid AS student_id,
                   e.payload_json->>'domain' AS domain,
                   e.payload_json->>'tier' AS tier,
                   e.event_id,
                   e.occurred_at,
                   (e.payload_json->>'score')::double precision AS score,
                   ROW_NUMBER() OVER (
                       PARTITION BY (e.payload_json->>'student_id')::uuid,
                                    e.payload_json->>'domain',
                                    e.payload_json->>'tier'
                       ORDER BY e.occurred_at, e.event_id
                   ) AS event_no,
                   COUNT(*) OVER (
                       PARTITION BY (e.payload_json->>'student_id')::uuid,
                                    e.payload_json->>'domain',
                                    e.payload_json->>'tier'
                   ) AS event_total
            FROM public.event_log e
            WHERE e.event_type = 'MASTERY_UPDATED'
        ), replay AS (
            SELECT student_id, domain, tier, event_no, event_total, score AS ema
            FROM ordered_events
            WHERE event_no = 1
            UNION ALL
            SELECT e.student_id, e.domain, e.tier, e.event_no, e.event_total,
                   (r.ema * 0.8) + (e.score * 0.2)
            FROM replay r
            JOIN ordered_events e
              ON e.student_id = r.student_id
             AND e.domain = r.domain
             AND e.tier = r.tier
             AND e.event_no = r.event_no + 1
        ), final_replay AS (
            SELECT DISTINCT ON (student_id, domain, tier)
                   student_id, domain, tier, ema
            FROM replay
            ORDER BY student_id, domain, tier, event_no DESC
        )
        SELECT 1
        FROM public.mastery_topic m
        JOIN final_replay r USING (student_id, domain, tier)
        WHERE ABS(m.ema_score - r.ema) > 1e-12
    ) THEN
        RAISE EXCEPTION 'cannot backfill mastery evidence_count: source-event EMA replay disagrees with mastery.ema_score';
    END IF;
END $$;

ALTER TABLE public.mastery_topic
    ADD COLUMN evidence_count BIGINT;

UPDATE public.mastery_topic m
SET evidence_count = s.evidence_count
FROM (
    SELECT (e.payload_json->>'student_id')::uuid AS student_id,
           e.payload_json->>'domain' AS domain,
           e.payload_json->>'tier' AS tier,
           COUNT(*)::bigint AS evidence_count
    FROM public.event_log e
    WHERE e.event_type = 'MASTERY_UPDATED'
    GROUP BY 1, 2, 3
) s
WHERE s.student_id = m.student_id
  AND s.domain = m.domain
  AND s.tier = m.tier;

ALTER TABLE public.mastery_topic
    ALTER COLUMN evidence_count SET NOT NULL,
    ALTER COLUMN evidence_count SET DEFAULT 1,
    ADD CONSTRAINT mastery_topic_evidence_count_nonnegative
        CHECK (evidence_count >= 0);

CREATE FUNCTION public.set_mastery_topic_evidence_count()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.evidence_count := 1;
    ELSIF NEW.ema_score IS DISTINCT FROM OLD.ema_score
       OR NEW.updated_at IS DISTINCT FROM OLD.updated_at THEN
        NEW.evidence_count := OLD.evidence_count + 1;
    ELSE
        -- The service cannot forge or reset the evidence count through an
        -- ordinary row update; it advances only with a new EMA observation.
        NEW.evidence_count := OLD.evidence_count;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER mastery_topic_evidence_count_write
BEFORE INSERT OR UPDATE ON public.mastery_topic
FOR EACH ROW EXECUTE FUNCTION public.set_mastery_topic_evidence_count();

GRANT SELECT (evidence_count)
    ON public.mastery_topic TO platform_api_svc;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mathprep_platform_local') THEN
        GRANT SELECT (evidence_count)
            ON public.mastery_topic TO mathprep_platform_local;
    END IF;
END $$;
