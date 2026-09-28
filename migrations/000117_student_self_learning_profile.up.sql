-- Private development-only practice profiles for independently registered
-- students. These rows are structurally separate from family children,
-- guardians, and consents.
CREATE TABLE mathprep.platform_student_self_profile (
    profile_id UUID PRIMARY KEY,
    student_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    student_tenant_id UUID NOT NULL REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT,
    engine_student_id UUID NOT NULL UNIQUE REFERENCES public.students(user_id) ON DELETE RESTRICT,
    name TEXT NOT NULL CHECK (char_length(name) BETWEEN 1 AND 40),
    grade SMALLINT NOT NULL CHECK (grade BETWEEN 1 AND 11),
    locale TEXT NOT NULL CHECK (locale IN ('ru','kk','en')),
    preview_notice_version TEXT NOT NULL CHECK (preview_notice_version = 'student-self-preview-v1'),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    UNIQUE (student_principal_id, student_tenant_id),
    UNIQUE (profile_id, engine_student_id)
);

CREATE FUNCTION mathprep.assert_student_self_profile_owner()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, mathprep AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM mathprep.access_principals p
        JOIN mathprep.access_memberships m ON m.principal_id=p.id AND m.tenant_id=NEW.student_tenant_id
        JOIN mathprep.access_tenants t ON t.id=m.tenant_id
        WHERE p.id=NEW.student_principal_id AND p.status='active'
          AND m.status='active' AND m.role='student'
          AND t.status='active' AND t.kind='student'
    ) THEN RAISE EXCEPTION 'self-owned profile requires the exact active student membership'; END IF;
    RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION mathprep.assert_student_self_profile_owner() FROM PUBLIC;
CREATE TRIGGER platform_student_self_profile_owner_guard
    BEFORE INSERT ON mathprep.platform_student_self_profile
    FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_self_profile_owner();

-- Preserve the existing family child FK. Each session belongs to exactly one
-- family child OR one self-owned profile; it never points at both.
ALTER TABLE mathprep.platform_learning_sessions ALTER COLUMN child_id DROP NOT NULL;
ALTER TABLE mathprep.platform_learning_sessions
    ADD COLUMN self_profile_id UUID REFERENCES mathprep.platform_student_self_profile(profile_id) ON DELETE RESTRICT;
ALTER TABLE mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_one_owner_check
    CHECK ((child_id IS NOT NULL AND self_profile_id IS NULL) OR (child_id IS NULL AND self_profile_id IS NOT NULL));
CREATE UNIQUE INDEX platform_learning_sessions_self_idempotency_idx
    ON mathprep.platform_learning_sessions(self_profile_id,idempotency_key)
    WHERE self_profile_id IS NOT NULL;
CREATE INDEX platform_learning_sessions_profile_idx
    ON mathprep.platform_learning_sessions(self_profile_id,created_at DESC)
    WHERE self_profile_id IS NOT NULL;

REVOKE ALL PRIVILEGES ON mathprep.platform_student_self_profile FROM PUBLIC, platform_api_svc;
GRANT SELECT ON mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT (profile_id,student_principal_id,student_tenant_id,engine_student_id,name,grade,locale,preview_notice_version)
    ON mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT (self_profile_id) ON mathprep.platform_learning_sessions TO platform_api_svc;
GRANT INSERT (id,tenant_id,event_type,actor_principal_id,correlation_id,safe_payload)
    ON mathprep.access_audit_events TO platform_api_svc;
DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='mathprep_platform_local') THEN
        GRANT SELECT ON mathprep.platform_student_self_profile TO mathprep_platform_local;
        GRANT INSERT (profile_id,student_principal_id,student_tenant_id,engine_student_id,name,grade,locale,preview_notice_version)
            ON mathprep.platform_student_self_profile TO mathprep_platform_local;
        GRANT INSERT (self_profile_id) ON mathprep.platform_learning_sessions TO mathprep_platform_local;
        GRANT INSERT (id,tenant_id,event_type,actor_principal_id,correlation_id,safe_payload)
            ON mathprep.access_audit_events TO mathprep_platform_local;
    END IF;
END $$;
