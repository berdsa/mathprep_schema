-- Explicit, one-use student-to-family pairing. It does not merge principals,
-- copy phone identities, create guardian relationships, or grant consent.
CREATE TABLE mathprep.platform_student_profile_link (
    link_id UUID PRIMARY KEY,
    student_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT,
    student_tenant_id UUID NOT NULL REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT,
    family_tenant_id UUID REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT,
    child_id UUID REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT,
    pairing_code_digest TEXT CHECK (pairing_code_digest IS NULL OR pairing_code_digest ~ '^[a-f0-9]{64}$'),
    status TEXT NOT NULL CHECK (status IN ('pending_family', 'pending_student', 'active', 'rejected', 'revoked', 'expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT transaction_timestamp(),
    expires_at TIMESTAMPTZ NOT NULL,
    family_confirmed_at TIMESTAMPTZ,
    student_confirmed_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    CHECK (expires_at > created_at AND expires_at <= created_at + interval '15 minutes'),
    CHECK (
        (status = 'pending_family' AND family_tenant_id IS NULL AND child_id IS NULL AND pairing_code_digest IS NOT NULL AND family_confirmed_at IS NULL AND student_confirmed_at IS NULL AND closed_at IS NULL)
        OR (status = 'pending_student' AND family_tenant_id IS NOT NULL AND child_id IS NOT NULL AND pairing_code_digest IS NULL AND family_confirmed_at IS NOT NULL AND student_confirmed_at IS NULL AND closed_at IS NULL)
        OR (status = 'active' AND family_tenant_id IS NOT NULL AND child_id IS NOT NULL AND pairing_code_digest IS NULL AND family_confirmed_at IS NOT NULL AND student_confirmed_at IS NOT NULL AND closed_at IS NULL)
        OR (status IN ('rejected', 'revoked') AND pairing_code_digest IS NULL AND closed_at IS NOT NULL)
        OR (status = 'expired' AND pairing_code_digest IS NULL AND closed_at IS NOT NULL AND closed_at >= expires_at)
    ),
    CHECK (family_confirmed_at IS NULL OR (family_confirmed_at >= created_at AND family_confirmed_at <= expires_at)),
    CHECK (student_confirmed_at IS NULL OR (student_confirmed_at >= family_confirmed_at AND student_confirmed_at <= expires_at)),
    CHECK (closed_at IS NULL OR closed_at >= created_at)
);

CREATE UNIQUE INDEX platform_student_profile_link_code_idx
    ON mathprep.platform_student_profile_link(pairing_code_digest)
    WHERE status = 'pending_family';
CREATE UNIQUE INDEX platform_student_profile_link_student_open_idx
    ON mathprep.platform_student_profile_link(student_principal_id)
    WHERE status IN ('pending_family', 'pending_student', 'active');
CREATE UNIQUE INDEX platform_student_profile_link_child_open_idx
    ON mathprep.platform_student_profile_link(child_id)
    WHERE child_id IS NOT NULL AND status IN ('pending_student', 'active');
CREATE INDEX platform_student_profile_link_expiry_idx
    ON mathprep.platform_student_profile_link(expires_at)
    WHERE status IN ('pending_family', 'pending_student');

CREATE FUNCTION mathprep.assert_student_profile_link_scope()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, mathprep
AS $$
DECLARE
    student_kind TEXT;
    child_tenant UUID;
    child_learner UUID;
    family_kind TEXT;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.status IN ('rejected','revoked','expired') THEN
        RETURN NEW;
    END IF;
    SELECT t.kind INTO student_kind
      FROM mathprep.access_tenants t
      JOIN mathprep.access_memberships m ON m.tenant_id=t.id
      JOIN mathprep.access_principals p ON p.id=m.principal_id
     WHERE t.id=NEW.student_tenant_id AND m.principal_id=NEW.student_principal_id
       AND t.status='active' AND m.status='active' AND m.role='student' AND p.status='active';
    IF student_kind IS DISTINCT FROM 'student' THEN
        RAISE EXCEPTION 'student profile link requires an active student account';
    END IF;
    IF NEW.child_id IS NOT NULL THEN
        SELECT c.tenant_id,c.learner_id INTO child_tenant,child_learner
          FROM mathprep.platform_children c
         WHERE c.id=NEW.child_id AND c.status='active';
        SELECT kind INTO family_kind FROM mathprep.access_tenants WHERE id=NEW.family_tenant_id AND status='active';
        IF child_tenant IS DISTINCT FROM NEW.family_tenant_id OR family_kind IS DISTINCT FROM 'family'
           OR NOT EXISTS (
             SELECT 1 FROM mathprep.access_guardian_relationships g
             JOIN mathprep.access_memberships gm ON gm.tenant_id=g.tenant_id AND gm.principal_id=g.guardian_principal_id
             JOIN mathprep.access_principals gp ON gp.id=gm.principal_id AND gp.status='active'
             JOIN mathprep.access_tenants gt ON gt.id=gm.tenant_id AND gt.status='active'
             JOIN mathprep.access_consents ac ON ac.guardian_relationship_id=g.id
                AND ac.actor_principal_id=g.guardian_principal_id AND ac.tenant_id=g.tenant_id
             WHERE g.tenant_id=NEW.family_tenant_id AND g.learner_id=child_learner
               AND g.state IN ('declared','verified') AND gm.status='active'
               AND gm.role IN ('family_owner','guardian') AND ac.state='granted' AND ac.purpose='learning'
           ) THEN
            RAISE EXCEPTION 'student profile link requires an active consented family child';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.assert_student_profile_link_scope() FROM PUBLIC;
CREATE TRIGGER platform_student_profile_link_scope_guard
    BEFORE INSERT OR UPDATE ON mathprep.platform_student_profile_link
    FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_profile_link_scope();

CREATE FUNCTION mathprep.guard_student_profile_link_transition()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, mathprep
AS $$
BEGIN
    IF OLD.status NOT IN ('pending_family', 'pending_student', 'active')
       OR NEW.link_id IS DISTINCT FROM OLD.link_id
       OR NEW.student_principal_id IS DISTINCT FROM OLD.student_principal_id
       OR NEW.student_tenant_id IS DISTINCT FROM OLD.student_tenant_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.expires_at IS DISTINCT FROM OLD.expires_at THEN
        RAISE EXCEPTION 'student profile link is immutable outside its one-use lifecycle';
    END IF;
    IF OLD.status='pending_family' AND NEW.status IN ('pending_student','revoked','expired') THEN
        IF NEW.status='pending_student' AND (NEW.family_tenant_id IS NULL OR NEW.child_id IS NULL OR NEW.pairing_code_digest IS NOT NULL OR NEW.family_confirmed_at IS NULL OR NEW.student_confirmed_at IS NOT NULL OR NEW.closed_at IS NOT NULL) THEN
            RAISE EXCEPTION 'invalid family confirmation transition';
        END IF;
        IF NEW.status='expired' AND (NEW.pairing_code_digest IS NOT NULL OR NEW.closed_at < NEW.expires_at) THEN
            RAISE EXCEPTION 'invalid student link expiry transition';
        END IF;
        IF NEW.status='revoked' AND (NEW.pairing_code_digest IS NOT NULL OR NEW.closed_at IS NULL) THEN
            RAISE EXCEPTION 'cancelled student pairing requires a closed timestamp';
        END IF;
    ELSIF OLD.status='pending_student' AND NEW.status IN ('active','rejected','revoked','expired') THEN
        IF NEW.family_tenant_id IS DISTINCT FROM OLD.family_tenant_id OR NEW.child_id IS DISTINCT FROM OLD.child_id OR NEW.pairing_code_digest IS NOT NULL THEN
            RAISE EXCEPTION 'student confirmation cannot change selected family profile';
        END IF;
        IF NEW.status='active' AND (NEW.student_confirmed_at IS NULL OR NEW.closed_at IS NOT NULL) THEN
            RAISE EXCEPTION 'student confirmation timestamp required';
        END IF;
        IF NEW.status IN ('rejected','revoked') AND NEW.closed_at IS NULL THEN
            RAISE EXCEPTION 'closed link transition requires timestamp';
        END IF;
        IF NEW.status='expired' AND (NEW.closed_at < NEW.expires_at OR NEW.student_confirmed_at IS NOT NULL) THEN
            RAISE EXCEPTION 'invalid student link expiry transition';
        END IF;
    ELSIF OLD.status='active' AND NEW.status='revoked' THEN
        IF NEW.family_tenant_id IS DISTINCT FROM OLD.family_tenant_id OR NEW.child_id IS DISTINCT FROM OLD.child_id OR NEW.closed_at IS NULL OR NEW.pairing_code_digest IS NOT NULL THEN
            RAISE EXCEPTION 'link revocation may only close the existing relationship';
        END IF;
    ELSE
        RAISE EXCEPTION 'invalid student profile link transition';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION mathprep.guard_student_profile_link_transition() FROM PUBLIC;
CREATE TRIGGER platform_student_profile_link_lifecycle_guard
    BEFORE UPDATE ON mathprep.platform_student_profile_link
    FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_profile_link_transition();

REVOKE ALL PRIVILEGES ON mathprep.platform_student_profile_link FROM PUBLIC, platform_api_svc;
GRANT SELECT ON mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT (link_id,student_principal_id,student_tenant_id,pairing_code_digest,status,expires_at)
    ON mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE (family_tenant_id,child_id,pairing_code_digest,status,family_confirmed_at,student_confirmed_at,closed_at)
    ON mathprep.platform_student_profile_link TO platform_api_svc;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='mathprep_platform_local') THEN
        GRANT SELECT ON mathprep.platform_student_profile_link TO mathprep_platform_local;
        GRANT INSERT (link_id,student_principal_id,student_tenant_id,pairing_code_digest,status,expires_at)
            ON mathprep.platform_student_profile_link TO mathprep_platform_local;
        GRANT UPDATE (family_tenant_id,child_id,pairing_code_digest,status,family_confirmed_at,student_confirmed_at,closed_at)
            ON mathprep.platform_student_profile_link TO mathprep_platform_local;
    END IF;
END;
$$;
