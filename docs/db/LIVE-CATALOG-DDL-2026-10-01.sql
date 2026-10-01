--
-- PostgreSQL database dump
--

\restrict dR7cXfcHMyZjWVGHf10gqHuW574khhxqdOo2PNksZ98KjcLbEyQOnaodgRQsn1q

-- Dumped from database version 16.15 (Debian 16.15-1.pgdg13+2)
-- Dumped by pg_dump version 16.15 (Debian 16.15-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: mathprep; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mathprep;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: access_consent_tenant_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.access_consent_tenant_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE relationship_tenant uuid; relationship_actor uuid;
BEGIN
 IF NEW.guardian_relationship_id IS NOT NULL THEN
  SELECT tenant_id,guardian_principal_id INTO relationship_tenant,relationship_actor
    FROM mathprep.access_guardian_relationships WHERE id=NEW.guardian_relationship_id;
  IF relationship_tenant IS NULL OR relationship_tenant<>NEW.tenant_id OR relationship_actor<>NEW.actor_principal_id THEN
   RAISE EXCEPTION 'consent actor or tenant does not match guardian relationship';
  END IF;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM mathprep.access_memberships WHERE tenant_id=NEW.tenant_id AND principal_id=NEW.actor_principal_id AND status='active') THEN
  RAISE EXCEPTION 'consent actor lacks active tenant membership';
 END IF;
 RETURN NEW;
END $$;


--
-- Name: access_null_consent_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.access_null_consent_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF NEW.guardian_relationship_id IS NULL AND NEW.state='granted' THEN
  PERFORM 1 FROM mathprep.access_tenants WHERE id=NEW.tenant_id FOR UPDATE;
  IF EXISTS(SELECT 1 FROM mathprep.access_consents WHERE tenant_id=NEW.tenant_id AND guardian_relationship_id IS NULL AND purpose=NEW.purpose AND state='granted' AND id<>NEW.id) THEN
   RAISE EXCEPTION 'active null-linked consent already exists' USING ERRCODE='23505';
  END IF;
 END IF;
 RETURN NEW;
END $$;


--
-- Name: access_recovery_tenant_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.access_recovery_tenant_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM mathprep.access_memberships
    WHERE tenant_id=NEW.tenant_id AND principal_id=NEW.principal_id AND status IN ('active','pending_verification')
  ) THEN RAISE EXCEPTION 'recovery principal lacks tenant membership'; END IF;
  RETURN NEW;
END $$;


--
-- Name: assert_student_access_intent_scope(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.assert_student_access_intent_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
DECLARE
    child_tenant UUID;
    child_principal UUID;
    child_learner UUID;
    relationship_tenant UUID;
    relationship_guardian UUID;
    relationship_learner UUID;
    tenant_kind TEXT;
BEGIN
    SELECT tenant_id, principal_id, learner_id
      INTO child_tenant, child_principal, child_learner
      FROM mathprep.platform_children WHERE id = NEW.child_id;
    SELECT tenant_id, guardian_principal_id, learner_id
      INTO relationship_tenant, relationship_guardian, relationship_learner
      FROM mathprep.access_guardian_relationships WHERE id = NEW.guardian_relationship_id;
    SELECT kind INTO tenant_kind FROM mathprep.access_tenants WHERE id = NEW.tenant_id;
    IF tenant_kind IS DISTINCT FROM 'family'
       OR child_tenant IS DISTINCT FROM NEW.tenant_id
       OR child_principal IS DISTINCT FROM NEW.child_principal_id
       OR relationship_tenant IS DISTINCT FROM NEW.tenant_id
       OR relationship_guardian IS DISTINCT FROM NEW.guardian_principal_id
       OR relationship_learner IS DISTINCT FROM child_learner THEN
        RAISE EXCEPTION 'student access intent child and guardian scope do not match';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: assert_student_phone_enrollment_scope(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.assert_student_phone_enrollment_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM mathprep.access_principals p
        JOIN mathprep.access_memberships m ON m.principal_id = p.id
        JOIN mathprep.access_tenants t ON t.id = m.tenant_id
        WHERE p.id = NEW.principal_id AND p.status = 'active'
          AND m.id = NEW.membership_id AND m.status = 'active' AND m.role = 'student'
          AND t.status = 'active' AND t.kind = 'student'
    ) THEN
        RAISE EXCEPTION 'phone enrollment requires the exact active student membership';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: assert_student_profile_link_scope(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.assert_student_profile_link_scope() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
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


--
-- Name: assert_student_self_profile_owner(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.assert_student_self_profile_owner() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
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


--
-- Name: assign_legacy_tenant(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.assign_legacy_tenant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE expected_tenant uuid;
BEGIN
  SELECT tenant_id INTO expected_tenant FROM mathprep.parents WHERE id=NEW.parent_id;
  IF expected_tenant IS NULL THEN RAISE EXCEPTION 'parent tenant is required'; END IF;
  IF NEW.tenant_id IS NULL THEN NEW.tenant_id := expected_tenant;
  ELSIF NEW.tenant_id <> expected_tenant THEN RAISE EXCEPTION 'cross-tenant legacy write rejected'; END IF;
  RETURN NEW;
END $$;


--
-- Name: guard_student_access_intent_transition(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.guard_student_access_intent_transition() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
BEGIN
    IF OLD.status <> 'pending'
       OR NEW.status NOT IN ('finalized', 'expired')
       OR NEW.finalized_at IS NULL
       OR NEW.tenant_id IS DISTINCT FROM OLD.tenant_id
       OR NEW.child_id IS DISTINCT FROM OLD.child_id
       OR NEW.child_principal_id IS DISTINCT FROM OLD.child_principal_id
       OR NEW.guardian_relationship_id IS DISTINCT FROM OLD.guardian_relationship_id
       OR NEW.guardian_principal_id IS DISTINCT FROM OLD.guardian_principal_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
       OR NEW.email IS NOT NULL OR NEW.password_hash IS NOT NULL
       OR NEW.phone_e164 IS NOT NULL OR NEW.device_binding IS NOT NULL THEN
        RAISE EXCEPTION 'student access intent permits only one-use finalization or expiry with secret scrubbing';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_student_phone_enrollment_transition(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.guard_student_phone_enrollment_transition() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
BEGIN
    IF OLD.status <> 'pending'
       OR NEW.status NOT IN ('completed','expired')
       OR NEW.completed_at IS NULL
       OR NEW.intent_id IS DISTINCT FROM OLD.intent_id
       OR NEW.principal_id IS DISTINCT FROM OLD.principal_id
       OR NEW.membership_id IS DISTINCT FROM OLD.membership_id
       OR NEW.created_at IS DISTINCT FROM OLD.created_at
       OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
       OR NEW.device_binding IS NOT NULL THEN
        RAISE EXCEPTION 'phone enrollment intent permits only one-use completion or expiry with binding scrubbing';
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: guard_student_profile_link_transition(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.guard_student_profile_link_transition() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'mathprep'
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


--
-- Name: guardian_relationship_tenant_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.guardian_relationship_tenant_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE learner_tenant uuid;
BEGIN
  SELECT tenant_id INTO learner_tenant FROM mathprep.learners WHERE id=NEW.learner_id;
  IF learner_tenant IS NULL OR learner_tenant <> NEW.tenant_id THEN RAISE EXCEPTION 'cross-tenant guardian relationship rejected'; END IF;
  RETURN NEW;
END $$;


--
-- Name: limit_active_learners(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.limit_active_learners() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE learner_count integer;
BEGIN
 PERFORM 1 FROM mathprep.parents WHERE id=NEW.parent_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM mathprep.access_legacy_parent_mappings pm JOIN mathprep.platform_accounts a ON a.principal_id=pm.principal_id WHERE pm.parent_id=NEW.parent_id AND pm.migration_state='active') THEN
  RETURN NEW;
 END IF;
 SELECT count(*) INTO learner_count FROM mathprep.learners WHERE parent_id=NEW.parent_id AND status IN ('active','deleting') AND id<>NEW.id;
 IF NEW.status IN ('active','deleting') AND learner_count>=2 THEN RAISE EXCEPTION 'maximum two active learners'; END IF;
 RETURN NEW;
END $$;


--
-- Name: platform_child_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.platform_child_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM mathprep.learners WHERE id=NEW.learner_id AND tenant_id=NEW.tenant_id) THEN
  RAISE EXCEPTION 'child learner tenant mismatch';
 END IF;
 RETURN NEW;
END $$;


--
-- Name: platform_license_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.platform_license_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE school_tenant uuid; school_region text;
BEGIN
 SELECT tenant_id,region_id INTO school_tenant,school_region FROM mathprep.platform_schools WHERE id=NEW.school_id;
 IF TG_OP='INSERT' THEN
  IF NEW.status<>'pending' OR NOT EXISTS(SELECT 1 FROM mathprep.access_memberships m JOIN mathprep.access_principals p ON p.id=m.principal_id AND p.status='active' JOIN mathprep.access_tenants t ON t.id=m.tenant_id AND t.status='active' WHERE m.principal_id=NEW.requested_by AND m.tenant_id=school_tenant AND m.role='school_admin' AND m.status='active') THEN
   RAISE EXCEPTION 'license request requires active school administrator and pending state';
  END IF;
 ELSE
  IF NEW.school_id<>OLD.school_id OR NEW.requested_by<>OLD.requested_by OR NEW.seats<>OLD.seats OR NEW.note<>OLD.note OR NEW.created_at<>OLD.created_at THEN
   RAISE EXCEPTION 'license request evidence is immutable';
  END IF;
  IF OLD.status<>'pending' THEN RAISE EXCEPTION 'license decision is final'; END IF;
  IF NEW.status NOT IN ('approved','declined') OR NOT EXISTS(SELECT 1 FROM mathprep.access_memberships m JOIN mathprep.access_principals p ON p.id=m.principal_id AND p.status='active' JOIN mathprep.access_tenants t ON t.id=m.tenant_id AND t.status='active' WHERE m.principal_id=NEW.decided_by AND m.role='regional_official' AND m.region_id=school_region AND m.status='active') THEN
   RAISE EXCEPTION 'license decision requires matching active regional authority';
  END IF;
 END IF;
 RETURN NEW;
END $$;


--
-- Name: platform_teacher_class_guard(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.platform_teacher_class_guard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM mathprep.platform_classes c JOIN mathprep.platform_schools s ON s.id=c.school_id JOIN mathprep.access_memberships m ON m.tenant_id=s.tenant_id WHERE c.id=NEW.class_id AND m.principal_id=NEW.principal_id AND m.role='teacher' AND m.status='active') THEN
  RAISE EXCEPTION 'active teacher membership in class school required';
 END IF;
 RETURN NEW;
END $$;


--
-- Name: prune_platform_preauth_state(integer); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.prune_platform_preauth_state(batch_size integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
DECLARE
    removed integer := 0;
    affected integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;

    DELETE FROM mathprep.platform_registration_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_registration_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_login_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_login_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_trusted_device
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_trusted_device
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
           OR revoked_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;

    DELETE FROM mathprep.platform_password_recovery_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_password_recovery_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    removed := removed + affected;
    RETURN removed;
END;
$$;


--
-- Name: prune_platform_student_access_intents(integer); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.prune_platform_student_access_intents(batch_size integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
DECLARE
    removed integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;
    DELETE FROM mathprep.platform_student_access_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_student_access_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;


--
-- Name: prune_platform_student_phone_enrollment_intents(integer); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(batch_size integer) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'mathprep'
    AS $$
DECLARE removed integer := 0;
BEGIN
    IF batch_size < 1 OR batch_size > 500 THEN
        RAISE EXCEPTION 'batch_size must be between 1 and 500';
    END IF;
    DELETE FROM mathprep.platform_student_phone_enrollment_intent
    WHERE ctid IN (
        SELECT ctid FROM mathprep.platform_student_phone_enrollment_intent
        WHERE expires_at <= transaction_timestamp() - interval '24 hours'
        ORDER BY expires_at LIMIT batch_size
    );
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;


--
-- Name: reject_mutation(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.reject_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN RAISE EXCEPTION 'append-only relation: %', TG_TABLE_NAME; END $$;


--
-- Name: validate_item_skill_language(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.validate_item_skill_language() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE version_language varchar(8); topic_language varchar(8);
BEGIN
  SELECT language_code INTO STRICT version_language FROM mathprep.item_versions WHERE id=NEW.item_version_id;
  SELECT topic.language_code INTO STRICT topic_language
    FROM mathprep.skills skill JOIN mathprep.topics topic ON topic.id=skill.topic_id
    WHERE skill.id=NEW.skill_id;
  IF version_language <> topic_language THEN
    RAISE EXCEPTION 'item version and skill language mismatch' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;


--
-- Name: validate_pack_item_language(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.validate_pack_item_language() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE profile_language varchar(8); item_language varchar(8); topic_language varchar(8); curriculum_id uuid;
BEGIN
  SELECT profile.language_code, pack.curriculum_version_id
    INTO STRICT profile_language, curriculum_id
    FROM mathprep.packs pack JOIN mathprep.learner_profiles profile ON profile.id=pack.profile_id
    WHERE pack.id=NEW.pack_id;
  SELECT version.language_code, topic.language_code
    INTO STRICT item_language, topic_language
    FROM mathprep.item_versions version
    JOIN mathprep.item_version_skills link ON link.item_version_id=version.id AND link.is_primary
    JOIN mathprep.skills skill ON skill.id=link.skill_id
    JOIN mathprep.topics topic ON topic.id=skill.topic_id
    WHERE version.id=NEW.source_item_version_id;
  IF item_language <> profile_language OR topic_language <> profile_language
     OR NOT EXISTS(SELECT 1 FROM mathprep.topics topic WHERE topic.id IN (
       SELECT skill.topic_id FROM mathprep.item_version_skills link JOIN mathprep.skills skill ON skill.id=link.skill_id
       WHERE link.item_version_id=NEW.source_item_version_id
     ) AND topic.curriculum_version_id=curriculum_id AND topic.language_code=profile_language) THEN
    RAISE EXCEPTION 'pack item language or curriculum mismatch' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;


--
-- Name: validate_pack_language(); Type: FUNCTION; Schema: mathprep; Owner: -
--

CREATE FUNCTION mathprep.validate_pack_language() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE profile_language varchar(8); curriculum_language varchar(8);
BEGIN
  SELECT language_code INTO STRICT profile_language FROM mathprep.learner_profiles WHERE id=NEW.profile_id;
  SELECT language_code INTO STRICT curriculum_language FROM mathprep.curriculum_versions WHERE id=NEW.curriculum_version_id;
  IF profile_language <> curriculum_language THEN
    RAISE EXCEPTION 'pack profile and curriculum language mismatch' USING ERRCODE='23514';
  END IF;
  RETURN NEW;
END $$;


--
-- Name: set_mastery_topic_evidence_count(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_mastery_topic_evidence_count() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'public'
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_audit_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_audit_events (
    id uuid NOT NULL,
    tenant_id uuid,
    event_type text NOT NULL,
    actor_principal_id uuid,
    correlation_id uuid NOT NULL,
    safe_payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT access_audit_events_safe_payload_check CHECK ((jsonb_typeof(safe_payload) = 'object'::text))
);


--
-- Name: access_consents; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_consents (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    guardian_relationship_id uuid,
    actor_principal_id uuid NOT NULL,
    purpose text NOT NULL,
    policy_version text NOT NULL,
    policy_sha256 character(64) NOT NULL,
    state text NOT NULL,
    granted_at timestamp with time zone NOT NULL,
    withdrawn_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT access_consents_check CHECK (((state = 'withdrawn'::text) = (withdrawn_at IS NOT NULL))),
    CONSTRAINT access_consents_state_check CHECK ((state = ANY (ARRAY['granted'::text, 'withdrawn'::text, 'expired'::text, 'superseded'::text])))
);


--
-- Name: access_external_identities; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_external_identities (
    id uuid NOT NULL,
    principal_id uuid NOT NULL,
    provider text NOT NULL,
    subject_ref text NOT NULL,
    assurance text DEFAULT 'low'::text NOT NULL,
    verified_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT access_external_identities_assurance_check CHECK ((assurance = ANY (ARRAY['low'::text, 'step_up'::text])))
);


--
-- Name: access_guardian_relationships; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_guardian_relationships (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    guardian_principal_id uuid NOT NULL,
    learner_id uuid NOT NULL,
    state text DEFAULT 'declared'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT access_guardian_relationships_state_check CHECK ((state = ANY (ARRAY['declared'::text, 'evidence_pending'::text, 'verified'::text, 'disputed'::text, 'revoked'::text, 'ended'::text])))
);


--
-- Name: access_invitations; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_invitations (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    recipient_identity_ref text NOT NULL,
    nonce_hash bytea NOT NULL,
    requested_role text NOT NULL,
    state text DEFAULT 'issued'::text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    accepted_at timestamp with time zone,
    created_by_principal_id uuid,
    idempotency_key uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    recipient_provider text,
    CONSTRAINT access_invitations_check CHECK ((expires_at > created_at)),
    CONSTRAINT access_invitations_nonce_hash_check CHECK ((octet_length(nonce_hash) = 32)),
    CONSTRAINT access_invitations_requested_role_check CHECK ((requested_role = ANY (ARRAY['family_owner'::text, 'guardian'::text, 'pending_adult'::text]))),
    CONSTRAINT access_invitations_state_check CHECK ((state = ANY (ARRAY['draft'::text, 'issued'::text, 'delivered'::text, 'opened'::text, 'accepted'::text, 'expired'::text, 'revoked'::text, 'consumed'::text])))
);


--
-- Name: access_legacy_parent_mappings; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_legacy_parent_mappings (
    parent_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    migration_state text DEFAULT 'active'::text NOT NULL,
    mapped_at timestamp with time zone DEFAULT now() NOT NULL,
    rollback_at timestamp with time zone,
    CONSTRAINT access_legacy_parent_mappings_migration_state_check CHECK ((migration_state = ANY (ARRAY['active'::text, 'rolled_back'::text, 'exception'::text])))
);


--
-- Name: access_memberships; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_memberships (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    role text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    region_id text,
    CONSTRAINT access_memberships_role_check CHECK ((role = ANY (ARRAY['family_owner'::text, 'guardian'::text, 'pending_adult'::text, 'support_l2'::text, 'billing'::text, 'student'::text, 'teacher'::text, 'school_admin'::text, 'regional_official'::text]))),
    CONSTRAINT access_memberships_status_check CHECK ((status = ANY (ARRAY['invited'::text, 'pending_verification'::text, 'active'::text, 'suspended'::text, 'revoked'::text, 'left'::text])))
);


--
-- Name: access_principals; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_principals (
    id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    CONSTRAINT access_principals_status_check CHECK ((status = ANY (ARRAY['provisional'::text, 'active'::text, 'restricted'::text, 'suspended'::text, 'closed'::text])))
);


--
-- Name: access_recovery_cases; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_recovery_cases (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    state text DEFAULT 'opened'::text NOT NULL,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    executed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT access_recovery_cases_state_check CHECK ((state = ANY (ARRAY['opened'::text, 'evidence_pending'::text, 'review'::text, 'approved'::text, 'rejected'::text, 'cancelled'::text, 'executed'::text, 'closed'::text])))
);


--
-- Name: access_tenants; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.access_tenants (
    id uuid NOT NULL,
    kind text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    display_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    CONSTRAINT access_tenants_kind_check CHECK ((kind = ANY (ARRAY['family'::text, 'organization'::text, 'student'::text]))),
    CONSTRAINT access_tenants_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'closed'::text])))
);


--
-- Name: adaptation_rule_versions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.adaptation_rule_versions (
    id uuid NOT NULL,
    semantic_version character varying(32) NOT NULL,
    config jsonb NOT NULL,
    config_hash character(64) NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    effective_from timestamp with time zone NOT NULL,
    retired_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT adaptation_rule_versions_config_check CHECK ((jsonb_typeof(config) = 'object'::text)),
    CONSTRAINT adaptation_rule_versions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'retired'::text])))
);


--
-- Name: answer_evaluation_revisions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.answer_evaluation_revisions (
    id uuid NOT NULL,
    attempt_answer_id uuid NOT NULL,
    score_revision_id uuid NOT NULL,
    outcome text NOT NULL,
    expected_answer_snapshot jsonb NOT NULL,
    comparison_trace jsonb NOT NULL,
    evidence_weight numeric(4,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT answer_evaluation_revisions_evidence_weight_check CHECK ((evidence_weight >= (0)::numeric)),
    CONSTRAINT answer_evaluation_revisions_outcome_check CHECK ((outcome = ANY (ARRAY['correct'::text, 'incorrect'::text, 'skipped'::text, 'voided'::text])))
);


--
-- Name: assistance_marks; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.assistance_marks (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    pack_item_id uuid,
    state text DEFAULT 'active'::text NOT NULL,
    reason text,
    marked_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT assistance_marks_state_check CHECK ((state = ANY (ARRAY['active'::text, 'revoked'::text])))
);


--
-- Name: attempt_answers; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.attempt_answers (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    pack_item_id uuid NOT NULL,
    raw_answer text,
    normalized_answer jsonb,
    submitted_answer_kind text,
    submitted_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: attempt_score_revisions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.attempt_score_revisions (
    id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    revision_no smallint NOT NULL,
    reason text NOT NULL,
    correct_count smallint NOT NULL,
    incorrect_count smallint NOT NULL,
    skipped_count smallint NOT NULL,
    voided_count smallint NOT NULL,
    denominator_count smallint NOT NULL,
    score_percent smallint,
    rule_snapshot jsonb NOT NULL,
    calculated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attempt_score_revisions_check CHECK ((((denominator_count = 0) AND (score_percent IS NULL)) OR ((denominator_count > 0) AND (score_percent IS NOT NULL)))),
    CONSTRAINT attempt_score_revisions_correct_count_check CHECK ((correct_count >= 0)),
    CONSTRAINT attempt_score_revisions_denominator_count_check CHECK ((denominator_count >= 0)),
    CONSTRAINT attempt_score_revisions_incorrect_count_check CHECK ((incorrect_count >= 0)),
    CONSTRAINT attempt_score_revisions_reason_check CHECK ((reason = ANY (ARRAY['initial_grade'::text, 'content_defect'::text]))),
    CONSTRAINT attempt_score_revisions_rule_snapshot_check CHECK ((jsonb_typeof(rule_snapshot) = 'object'::text)),
    CONSTRAINT attempt_score_revisions_score_percent_check CHECK (((score_percent >= 0) AND (score_percent <= 100))),
    CONSTRAINT attempt_score_revisions_skipped_count_check CHECK ((skipped_count >= 0)),
    CONSTRAINT attempt_score_revisions_voided_count_check CHECK ((voided_count >= 0))
);


--
-- Name: attempts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.attempts (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    attempt_no smallint NOT NULL,
    attempt_kind text NOT NULL,
    submission_idempotency_key uuid NOT NULL,
    submitted_at timestamp with time zone NOT NULL,
    client_device_class text DEFAULT 'unknown'::text NOT NULL,
    is_incomplete boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attempts_attempt_kind_check CHECK ((attempt_kind = ANY (ARRAY['initial'::text, 'retake'::text])))
);


--
-- Name: backup_artifact_manifests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.backup_artifact_manifests (
    id uuid NOT NULL,
    backup_run_id uuid NOT NULL,
    manifest_sha256 character(64) NOT NULL,
    artifact_count integer NOT NULL,
    byte_count bigint NOT NULL,
    artifact_backup_reference character varying(256),
    captured_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT backup_artifact_manifests_artifact_count_check CHECK ((artifact_count >= 0)),
    CONSTRAINT backup_artifact_manifests_byte_count_check CHECK ((byte_count >= 0))
);


--
-- Name: backup_runs; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.backup_runs (
    id uuid NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    status text NOT NULL,
    backup_reference character varying(256),
    checksum character(64),
    encrypted boolean NOT NULL,
    restore_tested_at timestamp with time zone,
    rpo_verified_at timestamp with time zone,
    safe_error_code character varying(64),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    backup_cutoff_at timestamp with time zone,
    schema_backup_reference character varying(256),
    schema_checksum character(64),
    region_evidence_reference_digest character(64),
    key_recovery_procedure_version character varying(64),
    CONSTRAINT backup_runs_status_check CHECK ((status = ANY (ARRAY['running'::text, 'succeeded'::text, 'failed'::text])))
);


--
-- Name: content_decision_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_decision_events (
    id uuid NOT NULL,
    item_version_id uuid,
    content_report_id uuid,
    content_incident_id uuid,
    action text NOT NULL,
    actor_parent_id uuid NOT NULL,
    actor_capability text NOT NULL,
    prior_status text,
    next_status text,
    evidence_hash character(64),
    reason_code character varying(64),
    correlation_id uuid NOT NULL,
    decided_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_decision_events_action_check CHECK ((action = ANY (ARRAY['imported'::text, 'validated'::text, 'submitted'::text, 'approved'::text, 'rejected'::text, 'quarantined'::text, 'incident_confirmed'::text, 'incident_resolved'::text]))),
    CONSTRAINT content_decision_events_actor_capability_check CHECK ((actor_capability = ANY (ARRAY['author'::text, 'reviewer'::text, 'approver'::text, 'importer'::text]))),
    CONSTRAINT content_decision_events_check CHECK ((num_nonnulls(item_version_id, content_report_id, content_incident_id) >= 1))
);


--
-- Name: content_incident_pack_items; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_incident_pack_items (
    incident_id uuid NOT NULL,
    pack_item_id uuid NOT NULL,
    action text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_incident_pack_items_action_check CHECK ((action = ANY (ARRAY['void'::text, 'no_impact'::text, 'corrected'::text])))
);


--
-- Name: content_incidents; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_incidents (
    id uuid NOT NULL,
    item_version_id uuid NOT NULL,
    severity text NOT NULL,
    state text DEFAULT 'confirmed'::text NOT NULL,
    confirmed_at timestamp with time zone NOT NULL,
    confirmed_by_parent_id uuid NOT NULL,
    corrected_item_version_id uuid,
    resolution text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_incidents_severity_check CHECK ((severity = ANY (ARRAY['critical'::text, 'substantial'::text, 'cosmetic'::text]))),
    CONSTRAINT content_incidents_state_check CHECK ((state = ANY (ARRAY['confirmed'::text, 'resolved'::text])))
);


--
-- Name: content_readiness_run_days; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_readiness_run_days (
    run_id uuid NOT NULL,
    simulation_date date NOT NULL,
    outcome text NOT NULL,
    selected_summary jsonb NOT NULL,
    violations jsonb NOT NULL,
    content_fingerprint_hash character(64) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_readiness_run_days_outcome_check CHECK ((outcome = ANY (ARRAY['valid'::text, 'invalid'::text]))),
    CONSTRAINT content_readiness_run_days_selected_summary_check CHECK ((jsonb_typeof(selected_summary) = 'object'::text)),
    CONSTRAINT content_readiness_run_days_violations_check CHECK ((jsonb_typeof(violations) = 'array'::text))
);


--
-- Name: content_readiness_runs; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_readiness_runs (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    rule_version_id uuid NOT NULL,
    curriculum_version_id uuid NOT NULL,
    content_cutoff_at timestamp with time zone NOT NULL,
    profile_snapshot jsonb NOT NULL,
    profile_snapshot_hash character(64) NOT NULL,
    simulation_start_on date NOT NULL,
    days_count smallint NOT NULL,
    status text NOT NULL,
    initiated_by_parent_id uuid,
    result_summary jsonb NOT NULL,
    result_hash character(64),
    started_at timestamp with time zone NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_readiness_runs_check CHECK (((status = ANY (ARRAY['passed'::text, 'failed'::text, 'invalidated'::text])) = (completed_at IS NOT NULL))),
    CONSTRAINT content_readiness_runs_days_count_check CHECK ((days_count = 30)),
    CONSTRAINT content_readiness_runs_profile_snapshot_check CHECK ((jsonb_typeof(profile_snapshot) = 'object'::text)),
    CONSTRAINT content_readiness_runs_result_summary_check CHECK ((jsonb_typeof(result_summary) = 'object'::text)),
    CONSTRAINT content_readiness_runs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'passed'::text, 'failed'::text, 'invalidated'::text])))
);


--
-- Name: content_reports; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.content_reports (
    id uuid NOT NULL,
    parent_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    pack_item_id uuid NOT NULL,
    defect_kind text NOT NULL,
    details text,
    state text DEFAULT 'open'::text NOT NULL,
    reported_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    resolved_by_parent_id uuid,
    resolution text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT content_reports_defect_kind_check CHECK ((defect_kind = ANY (ARRAY['condition'::text, 'options'::text, 'answer'::text, 'explanation'::text, 'render'::text]))),
    CONSTRAINT content_reports_state_check CHECK ((state = ANY (ARRAY['open'::text, 'confirmed'::text, 'rejected'::text])))
);


--
-- Name: curriculum_versions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.curriculum_versions (
    id uuid NOT NULL,
    code character varying(64) NOT NULL,
    country_code character varying(8) DEFAULT 'KZ'::character varying NOT NULL,
    subject_code character varying(16) DEFAULT 'math'::character varying NOT NULL,
    language_code character varying(8) DEFAULT 'ru'::character varying NOT NULL,
    academic_year character varying(9) NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT curriculum_versions_country_code_check CHECK (((country_code)::text = 'KZ'::text)),
    CONSTRAINT curriculum_versions_language_code_ck CHECK (((language_code)::text = ANY (ARRAY[('ru'::character varying)::text, ('kk'::character varying)::text]))),
    CONSTRAINT curriculum_versions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'retired'::text]))),
    CONSTRAINT curriculum_versions_subject_code_check CHECK (((subject_code)::text = 'math'::text))
);


--
-- Name: deletion_requests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.deletion_requests (
    id uuid NOT NULL,
    parent_id uuid,
    learner_id uuid,
    requested_at timestamp with time zone NOT NULL,
    confirmed_at timestamp with time zone NOT NULL,
    due_at timestamp with time zone NOT NULL,
    status text NOT NULL,
    completed_at timestamp with time zone,
    subject_digest character(64) NOT NULL,
    backup_purge_due_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT deletion_requests_check CHECK ((due_at <= (confirmed_at + '7 days'::interval))),
    CONSTRAINT deletion_requests_status_check CHECK ((status = ANY (ARRAY['requested'::text, 'confirmed'::text, 'purging'::text, 'completed'::text, 'failed'::text])))
);


--
-- Name: difficulty_override_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.difficulty_override_events (
    id uuid NOT NULL,
    override_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    event_type text NOT NULL,
    pack_id uuid,
    previous_remaining_pack_count smallint,
    new_remaining_pack_count smallint,
    replaced_by_override_id uuid,
    created_by_parent_id uuid,
    correlation_id uuid NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT difficulty_override_events_check CHECK (((event_type = 'consumed'::text) = (pack_id IS NOT NULL))),
    CONSTRAINT difficulty_override_events_check1 CHECK (((event_type = 'replaced'::text) = (replaced_by_override_id IS NOT NULL))),
    CONSTRAINT difficulty_override_events_event_type_check CHECK ((event_type = ANY (ARRAY['created'::text, 'consumed'::text, 'replaced'::text, 'cancelled'::text, 'restored_auto'::text])))
);


--
-- Name: difficulty_overrides; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.difficulty_overrides (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    direction text NOT NULL,
    target_difficulty smallint,
    scope text NOT NULL,
    remaining_pack_count smallint,
    status text DEFAULT 'active'::text NOT NULL,
    created_by_parent_id uuid NOT NULL,
    starts_at timestamp with time zone DEFAULT now() NOT NULL,
    ends_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    replaced_at timestamp with time zone,
    last_consumed_pack_id uuid,
    CONSTRAINT difficulty_overrides_check CHECK ((((scope = 'persistent'::text) AND (direction = 'fixed_level'::text)) OR (scope <> 'persistent'::text))),
    CONSTRAINT difficulty_overrides_direction_check CHECK ((direction = ANY (ARRAY['easier'::text, 'harder'::text, 'fixed_level'::text]))),
    CONSTRAINT difficulty_overrides_remaining_pack_count_check CHECK (((remaining_pack_count >= 1) AND (remaining_pack_count <= 3))),
    CONSTRAINT difficulty_overrides_scope_check CHECK ((scope = ANY (ARRAY['next_pack'::text, 'next_three'::text, 'persistent'::text]))),
    CONSTRAINT difficulty_overrides_status_check CHECK ((status = ANY (ARRAY['active'::text, 'consumed'::text, 'replaced'::text, 'cancelled'::text]))),
    CONSTRAINT difficulty_overrides_target_difficulty_check CHECK (((target_difficulty >= 1) AND (target_difficulty <= 5)))
);


--
-- Name: item_instances; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.item_instances (
    id uuid NOT NULL,
    item_version_id uuid NOT NULL,
    parameters jsonb NOT NULL,
    canonical_parameters_hash character(64) NOT NULL,
    option_order_hash character(64) NOT NULL,
    rendered_question jsonb NOT NULL,
    answer_spec jsonb NOT NULL,
    solution jsonb NOT NULL,
    validation_status text NOT NULL,
    generated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT item_instances_answer_spec_check CHECK ((jsonb_typeof(answer_spec) = 'object'::text)),
    CONSTRAINT item_instances_parameters_check CHECK ((jsonb_typeof(parameters) = 'object'::text)),
    CONSTRAINT item_instances_rendered_question_check CHECK ((jsonb_typeof(rendered_question) = 'object'::text)),
    CONSTRAINT item_instances_solution_check CHECK ((jsonb_typeof(solution) = 'object'::text)),
    CONSTRAINT item_instances_validation_status_check CHECK ((validation_status = ANY (ARRAY['passed'::text, 'failed'::text])))
);


--
-- Name: item_version_skills; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.item_version_skills (
    item_version_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: item_versions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.item_versions (
    id uuid NOT NULL,
    item_id uuid NOT NULL,
    version_no integer NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    language_code character varying(8) DEFAULT 'ru'::character varying NOT NULL,
    grade_min smallint NOT NULL,
    grade_max smallint NOT NULL,
    difficulty_level smallint NOT NULL,
    is_olympiad boolean DEFAULT false NOT NULL,
    expected_seconds integer NOT NULL,
    prompt jsonb NOT NULL,
    answer_spec jsonb NOT NULL,
    solution jsonb NOT NULL,
    source_attribution text NOT NULL,
    license_code character varying(64) NOT NULL,
    content_hash character(64) NOT NULL,
    approved_at timestamp with time zone,
    approved_by_parent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT item_versions_answer_spec_check CHECK ((jsonb_typeof(answer_spec) = 'object'::text)),
    CONSTRAINT item_versions_check CHECK (((grade_max >= grade_min) AND (grade_max <= 11))),
    CONSTRAINT item_versions_difficulty_level_check CHECK (((difficulty_level >= 1) AND (difficulty_level <= 5))),
    CONSTRAINT item_versions_expected_seconds_check CHECK ((expected_seconds > 0)),
    CONSTRAINT item_versions_grade_min_check CHECK (((grade_min >= 1) AND (grade_min <= 11))),
    CONSTRAINT item_versions_language_code_ck CHECK (((language_code)::text = ANY (ARRAY[('ru'::character varying)::text, ('kk'::character varying)::text]))),
    CONSTRAINT item_versions_prompt_check CHECK ((jsonb_typeof(prompt) = 'object'::text)),
    CONSTRAINT item_versions_solution_check CHECK ((jsonb_typeof(solution) = 'object'::text)),
    CONSTRAINT item_versions_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'in_review'::text, 'approved'::text, 'quarantined'::text, 'rejected'::text, 'archived'::text])))
);


--
-- Name: items; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.items (
    id uuid NOT NULL,
    stable_code character varying(96) NOT NULL,
    item_kind text NOT NULL,
    created_by_kind text NOT NULL,
    archived_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT items_created_by_kind_check CHECK ((created_by_kind = ANY (ARRAY['editor'::text, 'generator'::text]))),
    CONSTRAINT items_item_kind_check CHECK ((item_kind = ANY (ARRAY['static'::text, 'template'::text])))
);


--
-- Name: job_attempts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.job_attempts (
    id uuid NOT NULL,
    job_id uuid NOT NULL,
    attempt_no smallint NOT NULL,
    leased_by character varying(80) NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    outcome text NOT NULL,
    safe_error_code character varying(64),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT job_attempts_outcome_check CHECK ((outcome = ANY (ARRAY['succeeded'::text, 'retryable_failed'::text, 'terminal_failed'::text, 'cancelled'::text])))
);


--
-- Name: jobs; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.jobs (
    id uuid NOT NULL,
    job_type text NOT NULL,
    dedupe_key character varying(160) NOT NULL,
    profile_id uuid,
    pack_id uuid,
    payload_safe jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    run_after timestamp with time zone DEFAULT now() NOT NULL,
    lease_owner character varying(80),
    lease_expires_at timestamp with time zone,
    attempt_count smallint DEFAULT 0 NOT NULL,
    max_attempts smallint DEFAULT 3 NOT NULL,
    last_error_code character varying(64),
    correlation_id uuid NOT NULL,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    incident_id uuid,
    CONSTRAINT jobs_attempt_count_check CHECK (((attempt_count >= 0) AND (attempt_count <= 3))),
    CONSTRAINT jobs_job_type_check CHECK ((job_type = ANY (ARRAY['generate_pack'::text, 'render_pdf'::text, 'send_telegram'::text, 'manual_resend'::text, 'reminder'::text, 'weekly_summary'::text, 'regrade'::text, 'purge'::text, 'content_readiness_dry_run'::text, 'calculate_slo'::text]))),
    CONSTRAINT jobs_max_attempts_check CHECK (((max_attempts >= 1) AND (max_attempts <= 3))),
    CONSTRAINT jobs_payload_safe_check CHECK ((jsonb_typeof(payload_safe) = 'object'::text)),
    CONSTRAINT jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'leased'::text, 'retry_wait'::text, 'succeeded'::text, 'failed'::text, 'cancelled'::text])))
);


--
-- Name: learner_profiles; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.learner_profiles (
    id uuid NOT NULL,
    learner_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    curriculum_version_id uuid NOT NULL,
    grade_level smallint NOT NULL,
    academic_year character varying(9) NOT NULL,
    language_code character varying(8) DEFAULT 'ru'::character varying NOT NULL,
    active_quarter smallint DEFAULT 1 NOT NULL,
    active_topic_id uuid,
    base_difficulty smallint NOT NULL,
    adaptation_mode text DEFAULT 'auto'::text NOT NULL,
    default_pack_size smallint NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    started_on date,
    archived_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT learner_profiles_active_quarter_check CHECK (((active_quarter >= 1) AND (active_quarter <= 4))),
    CONSTRAINT learner_profiles_adaptation_mode_check CHECK ((adaptation_mode = ANY (ARRAY['auto'::text, 'fixed'::text]))),
    CONSTRAINT learner_profiles_base_difficulty_check CHECK (((base_difficulty >= 1) AND (base_difficulty <= 5))),
    CONSTRAINT learner_profiles_check CHECK ((((grade_level = 2) AND (default_pack_size = ANY (ARRAY[8, 12, 16]))) OR ((grade_level = 5) AND (default_pack_size = ANY (ARRAY[10, 14, 18]))))),
    CONSTRAINT learner_profiles_grade_level_check CHECK ((grade_level = ANY (ARRAY[2, 5]))),
    CONSTRAINT learner_profiles_language_code_ck CHECK (((language_code)::text = ANY (ARRAY[('ru'::character varying)::text, ('kk'::character varying)::text]))),
    CONSTRAINT learner_profiles_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'paused'::text, 'archived'::text, 'deleting'::text, 'deleted'::text])))
);


--
-- Name: learner_skill_projection; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.learner_skill_projection (
    profile_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    status text NOT NULL,
    window_attempts smallint NOT NULL,
    window_correct_weight numeric(6,3) NOT NULL,
    window_error_weight numeric(6,3) NOT NULL,
    last_attempt_at timestamp with time zone,
    next_review_on date,
    source_rule_version_id uuid NOT NULL,
    source_event_watermark timestamp with time zone NOT NULL,
    explanation jsonb DEFAULT '{}'::jsonb NOT NULL,
    calculated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT learner_skill_projection_status_check CHECK ((status = ANY (ARRAY['insufficient'::text, 'risk'::text, 'problem'::text, 'recovering'::text, 'mastered'::text]))),
    CONSTRAINT learner_skill_projection_window_attempts_check CHECK ((window_attempts >= 0)),
    CONSTRAINT learner_skill_projection_window_correct_weight_check CHECK ((window_correct_weight >= (0)::numeric)),
    CONSTRAINT learner_skill_projection_window_error_weight_check CHECK ((window_error_weight >= (0)::numeric))
);


--
-- Name: learners; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.learners (
    id uuid NOT NULL,
    parent_id uuid NOT NULL,
    pseudonym character varying(40) NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT learners_pseudonym_check CHECK (((length(btrim((pseudonym)::text)) >= 1) AND (length(btrim((pseudonym)::text)) <= 40))),
    CONSTRAINT learners_status_check CHECK ((status = ANY (ARRAY['active'::text, 'deleting'::text, 'deleted'::text])))
);


--
-- Name: operation_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.operation_events (
    id uuid NOT NULL,
    correlation_id uuid NOT NULL,
    component text NOT NULL,
    entity_type character varying(48) NOT NULL,
    entity_id uuid,
    stage character varying(64) NOT NULL,
    outcome text NOT NULL,
    error_code character varying(64),
    retry_no smallint DEFAULT 0 NOT NULL,
    safe_context jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT operation_events_component_check CHECK ((component = ANY (ARRAY['generator'::text, 'pdf'::text, 'qr'::text, 'telegram'::text, 'web'::text, 'checker'::text, 'db'::text]))),
    CONSTRAINT operation_events_safe_context_check CHECK ((jsonb_typeof(safe_context) = 'object'::text))
);


--
-- Name: pack_access_tokens; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_access_tokens (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    derivation_salt bytea NOT NULL,
    derivation_key_version smallint NOT NULL,
    token_hash bytea NOT NULL,
    display_code character(6) NOT NULL,
    input_expires_at timestamp with time zone,
    result_expires_at timestamp with time zone,
    extension_count smallint DEFAULT 0 NOT NULL,
    state text DEFAULT 'issued'::text NOT NULL,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoke_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    first_delivery_accepted_at timestamp with time zone,
    input_hard_expires_at timestamp with time zone,
    extended_at timestamp with time zone,
    extended_by_parent_id uuid,
    extension_command_id uuid,
    CONSTRAINT pack_access_extension_audit_ck CHECK ((((extension_count = 0) AND (extended_at IS NULL) AND (extended_by_parent_id IS NULL) AND (extension_command_id IS NULL)) OR ((extension_count = 1) AND (extended_at IS NOT NULL) AND (extended_by_parent_id IS NOT NULL) AND (extension_command_id IS NOT NULL)))),
    CONSTRAINT pack_access_first_accept_deadlines_ck CHECK ((((first_delivery_accepted_at IS NULL) AND (input_expires_at IS NULL) AND (input_hard_expires_at IS NULL) AND (result_expires_at IS NULL)) OR ((first_delivery_accepted_at IS NOT NULL) AND (input_expires_at IS NOT NULL) AND (input_hard_expires_at IS NOT NULL) AND (result_expires_at IS NOT NULL) AND (input_expires_at <= input_hard_expires_at) AND (input_hard_expires_at <= result_expires_at)))),
    CONSTRAINT pack_access_tokens_derivation_key_version_check CHECK ((derivation_key_version > 0)),
    CONSTRAINT pack_access_tokens_derivation_salt_check CHECK ((octet_length(derivation_salt) = 32)),
    CONSTRAINT pack_access_tokens_extension_count_check CHECK (((extension_count >= 0) AND (extension_count <= 1))),
    CONSTRAINT pack_access_tokens_state_check CHECK ((state = ANY (ARRAY['issued'::text, 'active'::text, 'revoked'::text]))),
    CONSTRAINT pack_access_tokens_token_hash_check CHECK ((octet_length(token_hash) = 32))
);


--
-- Name: pack_artifacts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_artifacts (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    artifact_kind text NOT NULL,
    object_key text NOT NULL,
    sha256 character(64) NOT NULL,
    bytes bigint NOT NULL,
    state text DEFAULT 'valid'::text NOT NULL,
    validated_at timestamp with time zone NOT NULL,
    rendered_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    delete_error_code character varying(64),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pack_artifacts_artifact_kind_check CHECK ((artifact_kind = 'parent_pdf'::text)),
    CONSTRAINT pack_artifacts_bytes_check CHECK ((bytes > 0)),
    CONSTRAINT pack_artifacts_state_check CHECK ((state = ANY (ARRAY['valid'::text, 'deleted'::text, 'purge_failed'::text])))
);


--
-- Name: pack_item_skills; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_item_skills (
    pack_item_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pack_item_skills_role_check CHECK ((role = ANY (ARRAY['primary'::text, 'secondary'::text])))
);


--
-- Name: pack_item_voids; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_item_voids (
    pack_item_id uuid NOT NULL,
    incident_id uuid NOT NULL,
    void_reason text NOT NULL,
    voided_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: pack_items; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_items (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    position_no smallint NOT NULL,
    source_item_id uuid NOT NULL,
    source_item_version_id uuid NOT NULL,
    primary_skill_id uuid NOT NULL,
    category text NOT NULL,
    difficulty_level smallint NOT NULL,
    is_olympiad boolean NOT NULL,
    instance_fingerprint character(64) NOT NULL,
    question_snapshot jsonb NOT NULL,
    answer_spec_snapshot jsonb NOT NULL,
    solution_snapshot jsonb NOT NULL,
    snapshot_hash character(64) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    item_instance_id uuid,
    CONSTRAINT pack_items_answer_spec_snapshot_check CHECK ((jsonb_typeof(answer_spec_snapshot) = 'object'::text)),
    CONSTRAINT pack_items_category_check CHECK ((category = ANY (ARRAY['problem'::text, 'current'::text, 'ahead'::text, 'olympiad'::text, 'diagnostic'::text, 'spaced_repetition'::text]))),
    CONSTRAINT pack_items_difficulty_level_check CHECK (((difficulty_level >= 1) AND (difficulty_level <= 5))),
    CONSTRAINT pack_items_position_no_check CHECK ((position_no > 0)),
    CONSTRAINT pack_items_question_snapshot_check CHECK ((jsonb_typeof(question_snapshot) = 'object'::text)),
    CONSTRAINT pack_items_solution_snapshot_check CHECK ((jsonb_typeof(solution_snapshot) = 'object'::text))
);


--
-- Name: pack_lifecycle_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.pack_lifecycle_events (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    event_type text NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    correlation_id uuid NOT NULL,
    safe_details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pack_lifecycle_events_event_type_check CHECK ((event_type = ANY (ARRAY['scheduled'::text, 'generating'::text, 'generated'::text, 'rendering'::text, 'rendered'::text, 'delivery_pending'::text, 'retry_scheduled'::text, 'delivery_failed'::text, 'delivered'::text, 'opened'::text, 'submitted'::text, 'graded'::text, 'generation_failed'::text, 'cancelled'::text, 'revoked'::text, 'corrected'::text]))),
    CONSTRAINT pack_lifecycle_events_safe_details_check CHECK ((jsonb_typeof(safe_details) = 'object'::text))
);


--
-- Name: packs; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.packs (
    id uuid NOT NULL,
    parent_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    local_date date NOT NULL,
    pack_type text NOT NULL,
    additional_ordinal smallint DEFAULT 0 NOT NULL,
    origin_idempotency_key uuid NOT NULL,
    base_difficulty smallint NOT NULL,
    rule_version_id uuid NOT NULL,
    curriculum_version_id uuid NOT NULL,
    generation_snapshot jsonb,
    generation_snapshot_hash character(64),
    sealed_at timestamp with time zone,
    generated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT packs_additional_ordinal_check CHECK ((additional_ordinal >= 0)),
    CONSTRAINT packs_base_difficulty_check CHECK (((base_difficulty >= 1) AND (base_difficulty <= 5))),
    CONSTRAINT packs_check CHECK ((((pack_type = 'planned'::text) AND (additional_ordinal = 0)) OR (pack_type = 'additional'::text))),
    CONSTRAINT packs_check1 CHECK ((((sealed_at IS NULL) AND (generation_snapshot IS NULL) AND (generation_snapshot_hash IS NULL)) OR ((sealed_at IS NOT NULL) AND (generation_snapshot IS NOT NULL) AND (generation_snapshot_hash IS NOT NULL)))),
    CONSTRAINT packs_pack_type_check CHECK ((pack_type = ANY (ARRAY['planned'::text, 'additional'::text])))
);


--
-- Name: parent_active_profiles; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.parent_active_profiles (
    parent_id uuid NOT NULL,
    profile_id uuid NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: parent_command_receipts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.parent_command_receipts (
    command_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    profile_id uuid,
    command_kind character varying(64) NOT NULL,
    source text NOT NULL,
    idempotency_key character varying(160) NOT NULL,
    outcome text NOT NULL,
    result_entity_type character varying(48),
    result_entity_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT parent_command_receipts_outcome_check CHECK ((outcome = ANY (ARRAY['accepted'::text, 'applied'::text, 'rejected'::text, 'failed'::text]))),
    CONSTRAINT parent_command_receipts_source_check CHECK ((source = ANY (ARRAY['telegram_callback'::text, 'telegram_command'::text, 'operator_cli'::text])))
);


--
-- Name: parent_consents; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.parent_consents (
    id uuid NOT NULL,
    parent_id uuid NOT NULL,
    consent_kind text NOT NULL,
    policy_version character varying(64) NOT NULL,
    policy_sha256 character(64) NOT NULL,
    telegram_user_id_snapshot bigint NOT NULL,
    granted_at timestamp with time zone NOT NULL,
    withdrawn_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT parent_consents_consent_kind_check CHECK ((consent_kind = ANY (ARRAY['personal_data'::text, 'terms'::text])))
);


--
-- Name: parents; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.parents (
    id uuid NOT NULL,
    telegram_user_id bigint,
    locale character varying(8) DEFAULT 'ru'::character varying NOT NULL,
    timezone character varying(64) DEFAULT 'Asia/Almaty'::character varying NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    last_activity_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id uuid NOT NULL,
    CONSTRAINT parents_locale_ck CHECK (((locale)::text = ANY (ARRAY[('ru'::character varying)::text, ('kk'::character varying)::text]))),
    CONSTRAINT parents_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'deleting'::text, 'deleted'::text]))),
    CONSTRAINT parents_telegram_user_id_check CHECK ((telegram_user_id > 0)),
    CONSTRAINT parents_timezone_check CHECK (((timezone)::text = 'Asia/Almaty'::text))
);


--
-- Name: phone_identity; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.phone_identity (
    phone_identity_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    phone_e164 text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    verified_at timestamp with time zone,
    revoked_at timestamp with time zone,
    CONSTRAINT phone_identity_check CHECK (((verified_at IS NULL) OR (verified_at >= created_at))),
    CONSTRAINT phone_identity_check1 CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
    CONSTRAINT phone_identity_check2 CHECK ((((status = 'pending'::text) AND (verified_at IS NULL) AND (revoked_at IS NULL)) OR ((status = 'verified'::text) AND (verified_at IS NOT NULL) AND (revoked_at IS NULL)) OR ((status = 'revoked'::text) AND (revoked_at IS NOT NULL)))),
    CONSTRAINT phone_identity_phone_e164_check CHECK ((phone_e164 ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT phone_identity_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'verified'::text, 'revoked'::text])))
);


--
-- Name: platform_accounts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_accounts (
    principal_id uuid NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    name text NOT NULL,
    locale text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    email_verified_at timestamp with time zone,
    CONSTRAINT platform_accounts_email_check CHECK ((email = lower(btrim(email)))),
    CONSTRAINT platform_accounts_locale_check CHECK ((locale = ANY (ARRAY['ru'::text, 'kk'::text, 'en'::text])))
);


--
-- Name: platform_checkouts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_checkouts (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    actor_principal_id uuid NOT NULL,
    idempotency_key uuid NOT NULL,
    child_ids uuid[] NOT NULL,
    amount_kzt integer NOT NULL,
    state text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_checkouts_amount_kzt_check CHECK ((amount_kzt > 0)),
    CONSTRAINT platform_checkouts_state_check CHECK ((state = 'development_simulated'::text))
);


--
-- Name: platform_children; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_children (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    student_id uuid NOT NULL,
    learner_id uuid NOT NULL,
    name text NOT NULL,
    grade integer NOT NULL,
    locale text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_children_grade_check CHECK (((grade >= 1) AND (grade <= 11))),
    CONSTRAINT platform_children_locale_check CHECK ((locale = ANY (ARRAY['ru'::text, 'kk'::text, 'en'::text]))),
    CONSTRAINT platform_children_name_check CHECK (((length(btrim(name)) >= 1) AND (length(btrim(name)) <= 40))),
    CONSTRAINT platform_children_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text])))
);


--
-- Name: platform_classes; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_classes (
    id uuid NOT NULL,
    school_id uuid NOT NULL,
    name text NOT NULL,
    grade integer NOT NULL,
    CONSTRAINT platform_classes_grade_check CHECK (((grade >= 1) AND (grade <= 11))),
    CONSTRAINT platform_classes_name_check CHECK (((length(name) >= 1) AND (length(name) <= 100)))
);


--
-- Name: platform_external_identities; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_external_identities (
    identity_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    provider text NOT NULL,
    subject text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT platform_external_identities_provider_check CHECK ((provider = 'google'::text)),
    CONSTRAINT platform_external_identities_subject_check CHECK (((length(subject) >= 1) AND (length(subject) <= 255)))
);


--
-- Name: platform_join_requests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_join_requests (
    id uuid NOT NULL,
    child_id uuid NOT NULL,
    class_id uuid NOT NULL,
    requested_by uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_by uuid,
    decided_at timestamp with time zone,
    CONSTRAINT platform_join_requests_check CHECK (((status = 'pending'::text) = (decided_at IS NULL))),
    CONSTRAINT platform_join_requests_check1 CHECK (((status = 'pending'::text) = (decided_by IS NULL))),
    CONSTRAINT platform_join_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'declined'::text])))
);


--
-- Name: platform_learning_answers; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_learning_answers (
    session_id uuid NOT NULL,
    item_id uuid NOT NULL,
    idempotency_key text NOT NULL,
    raw_input text NOT NULL,
    result jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: platform_learning_capabilities; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_learning_capabilities (
    code_hash bytea NOT NULL,
    session_id uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: platform_learning_drafts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_learning_drafts (
    session_id uuid NOT NULL,
    item_id uuid NOT NULL,
    raw_input text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: platform_learning_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_learning_events (
    id uuid NOT NULL,
    session_id uuid NOT NULL,
    kind text NOT NULL,
    idempotency_key text NOT NULL,
    occurred_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_learning_events_kind_check CHECK ((kind = ANY (ARRAY['focus_lost'::text, 'focus_returned'::text, 'offline'::text, 'online'::text])))
);


--
-- Name: platform_learning_sessions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_learning_sessions (
    id uuid NOT NULL,
    child_id uuid,
    mode text NOT NULL,
    status text DEFAULT 'generating'::text NOT NULL,
    topics jsonb NOT NULL,
    count integer NOT NULL,
    request_id uuid,
    items jsonb DEFAULT '[]'::jsonb NOT NULL,
    test_id uuid,
    device_id text,
    deadline timestamp with time zone,
    idempotency_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    finished_at timestamp with time zone,
    started_at timestamp with time zone,
    self_profile_id uuid,
    CONSTRAINT platform_learning_sessions_count_check CHECK (((count >= 1) AND (count <= 50))),
    CONSTRAINT platform_learning_sessions_mode_check CHECK ((mode = ANY (ARRAY['diagnostic'::text, 'practice'::text, 'test'::text, 'homework'::text]))),
    CONSTRAINT platform_learning_sessions_one_owner_check CHECK ((((child_id IS NOT NULL) AND (self_profile_id IS NULL)) OR ((child_id IS NULL) AND (self_profile_id IS NOT NULL)))),
    CONSTRAINT platform_learning_sessions_status_check CHECK ((status = ANY (ARRAY['generating'::text, 'active'::text, 'finalizing'::text, 'finished'::text, 'failed'::text])))
);


--
-- Name: platform_license_requests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_license_requests (
    id uuid NOT NULL,
    school_id uuid NOT NULL,
    requested_by uuid NOT NULL,
    seats integer NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    decided_by uuid,
    decision_note text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    CONSTRAINT platform_license_requests_check CHECK (((status = 'pending'::text) = (decided_at IS NULL))),
    CONSTRAINT platform_license_requests_check1 CHECK (((status = 'pending'::text) = (decided_by IS NULL))),
    CONSTRAINT platform_license_requests_decision_note_check CHECK ((length(decision_note) <= 1000)),
    CONSTRAINT platform_license_requests_note_check CHECK ((length(note) <= 1000)),
    CONSTRAINT platform_license_requests_seats_check CHECK (((seats >= 1) AND (seats <= 100000))),
    CONSTRAINT platform_license_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'declined'::text])))
);


--
-- Name: platform_login_intent; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_login_intent (
    intent_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    phone_identity_id uuid,
    device_binding text NOT NULL,
    device_token_digest text,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    CONSTRAINT platform_login_intent_check CHECK ((expires_at > created_at)),
    CONSTRAINT platform_login_intent_device_binding_check CHECK ((device_binding ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT platform_login_intent_device_token_digest_check CHECK (((device_token_digest IS NULL) OR (device_token_digest ~ '^[0-9a-f]{64}$'::text))),
    CONSTRAINT platform_login_intent_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'expired'::text])))
);


--
-- Name: platform_notifications; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_notifications (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    recipient_principal_id uuid NOT NULL,
    kind text NOT NULL,
    reference_id uuid,
    class_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone,
    session_id uuid,
    CONSTRAINT platform_notifications_event_reference_check CHECK ((((kind = 'assessment_ready'::text) AND (reference_id IS NULL) AND (session_id IS NOT NULL)) OR ((kind = ANY (ARRAY['join_requested'::text, 'join_approved'::text, 'join_declined'::text])) AND (reference_id IS NOT NULL) AND (session_id IS NULL)))),
    CONSTRAINT platform_notifications_kind_check CHECK ((kind = ANY (ARRAY['join_requested'::text, 'join_approved'::text, 'join_declined'::text, 'assessment_ready'::text])))
);


--
-- Name: platform_password_recovery_intent; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_password_recovery_intent (
    intent_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    phone_identity_id uuid,
    device_binding text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT platform_password_recovery_intent_check CHECK ((expires_at > created_at)),
    CONSTRAINT platform_password_recovery_intent_check1 CHECK ((((status = ANY (ARRAY['pending'::text, 'expired'::text])) AND (completed_at IS NULL)) OR ((status = 'completed'::text) AND (completed_at IS NOT NULL)))),
    CONSTRAINT platform_password_recovery_intent_check2 CHECK (((completed_at IS NULL) OR (completed_at >= created_at))),
    CONSTRAINT platform_password_recovery_intent_device_binding_check CHECK ((device_binding ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT platform_password_recovery_intent_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'expired'::text])))
);


--
-- Name: platform_placements; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_placements (
    child_id uuid NOT NULL,
    class_id uuid NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    ended_at timestamp with time zone,
    CONSTRAINT platform_placements_check CHECK (((status = 'ended'::text) = (ended_at IS NOT NULL))),
    CONSTRAINT platform_placements_status_check CHECK ((status = ANY (ARRAY['active'::text, 'ended'::text])))
);


--
-- Name: platform_push_outbox; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_push_outbox (
    notification_id uuid NOT NULL,
    recipient_principal_id uuid NOT NULL,
    event_kind text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    attempt_count smallint DEFAULT 0 NOT NULL,
    next_attempt_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    lease_token uuid,
    lease_expires_at timestamp with time zone,
    delivered_at timestamp with time zone,
    last_error_class text,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT platform_push_outbox_attempt_count_check CHECK (((attempt_count >= 0) AND (attempt_count <= 10))),
    CONSTRAINT platform_push_outbox_event_kind_check CHECK ((event_kind = ANY (ARRAY['join_requested'::text, 'join_approved'::text, 'join_declined'::text, 'assessment_ready'::text]))),
    CONSTRAINT platform_push_outbox_last_error_class_check CHECK (((last_error_class IS NULL) OR (last_error_class = ANY (ARRAY['transient'::text, 'permanent'::text, 'subscription_gone'::text, 'provider_unavailable'::text, 'internal'::text])))),
    CONSTRAINT platform_push_outbox_lifecycle_check CHECK ((((status = 'pending'::text) AND (lease_token IS NULL) AND (lease_expires_at IS NULL) AND (delivered_at IS NULL)) OR ((status = 'in_progress'::text) AND (lease_token IS NOT NULL) AND (lease_expires_at IS NOT NULL) AND (delivered_at IS NULL)) OR ((status = 'delivered'::text) AND (lease_token IS NULL) AND (lease_expires_at IS NULL) AND (delivered_at IS NOT NULL)) OR ((status = 'dead'::text) AND (lease_token IS NULL) AND (lease_expires_at IS NULL) AND (delivered_at IS NULL)))),
    CONSTRAINT platform_push_outbox_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'delivered'::text, 'dead'::text])))
);


--
-- Name: platform_push_preferences; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_push_preferences (
    principal_id uuid NOT NULL,
    quiet_start time without time zone,
    quiet_end time without time zone,
    time_zone text DEFAULT 'Asia/Almaty'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT platform_push_preferences_quiet_pair CHECK ((((quiet_start IS NULL) AND (quiet_end IS NULL)) OR ((quiet_start IS NOT NULL) AND (quiet_end IS NOT NULL) AND (quiet_start <> quiet_end))))
);


--
-- Name: platform_push_subscriptions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_push_subscriptions (
    id uuid NOT NULL,
    principal_id uuid NOT NULL,
    endpoint text NOT NULL,
    p256dh text NOT NULL,
    auth_secret text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone,
    revoked_at timestamp with time zone,
    CONSTRAINT platform_push_subscriptions_auth_secret_check CHECK (((length(auth_secret) >= 1) AND (length(auth_secret) <= 256))),
    CONSTRAINT platform_push_subscriptions_endpoint_check CHECK (((length(endpoint) >= 1) AND (length(endpoint) <= 2048))),
    CONSTRAINT platform_push_subscriptions_p256dh_check CHECK (((length(p256dh) >= 1) AND (length(p256dh) <= 256)))
);


--
-- Name: platform_registration_intent; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_registration_intent (
    intent_id uuid NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    display_name text NOT NULL,
    locale text NOT NULL,
    requested_role text NOT NULL,
    phone_e164 text,
    terms_version text NOT NULL,
    terms_acknowledged_at timestamp with time zone NOT NULL,
    device_binding text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    finalized_principal_id uuid,
    finalized_at timestamp with time zone,
    CONSTRAINT platform_registration_intent_check CHECK ((expires_at > created_at)),
    CONSTRAINT platform_registration_intent_check1 CHECK ((((status = 'pending'::text) AND (finalized_principal_id IS NULL) AND (finalized_at IS NULL)) OR ((status = 'finalized'::text) AND (finalized_principal_id IS NOT NULL) AND (finalized_at IS NOT NULL)) OR ((status = 'expired'::text) AND (finalized_principal_id IS NULL) AND (finalized_at IS NULL)))),
    CONSTRAINT platform_registration_intent_check2 CHECK (((finalized_at IS NULL) OR (finalized_at >= created_at))),
    CONSTRAINT platform_registration_intent_device_binding_check CHECK ((device_binding ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT platform_registration_intent_display_name_check CHECK (((length(btrim(display_name)) >= 1) AND (length(btrim(display_name)) <= 200))),
    CONSTRAINT platform_registration_intent_email_check CHECK ((email = lower(email))),
    CONSTRAINT platform_registration_intent_locale_check CHECK (((length(locale) >= 2) AND (length(locale) <= 16))),
    CONSTRAINT platform_registration_intent_password_hash_check CHECK (((length(password_hash) >= 1) AND (length(password_hash) <= 1024))),
    CONSTRAINT platform_registration_intent_phone_e164_check CHECK ((phone_e164 ~ '^\+[1-9][0-9]{1,14}$'::text)),
    CONSTRAINT platform_registration_intent_requested_role_check CHECK ((requested_role = ANY (ARRAY['family_owner'::text, 'student'::text]))),
    CONSTRAINT platform_registration_intent_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'finalized'::text, 'expired'::text]))),
    CONSTRAINT platform_registration_intent_terms_version_check CHECK (((length(terms_version) >= 1) AND (length(terms_version) <= 64)))
);


--
-- Name: platform_schools; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_schools (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    region_id text NOT NULL,
    name text NOT NULL,
    CONSTRAINT platform_schools_name_check CHECK (((length(name) >= 1) AND (length(name) <= 200))),
    CONSTRAINT platform_schools_region_id_check CHECK (((length(region_id) >= 1) AND (length(region_id) <= 100)))
);


--
-- Name: platform_sessions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_sessions (
    token_hash bytea NOT NULL,
    principal_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT platform_sessions_token_hash_check CHECK ((octet_length(token_hash) = 32))
);


--
-- Name: platform_staff_requests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_staff_requests (
    id uuid NOT NULL,
    principal_id uuid NOT NULL,
    school_id uuid NOT NULL,
    requested_role text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    decided_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    decided_at timestamp with time zone,
    CONSTRAINT platform_staff_requests_check CHECK (((status = 'pending'::text) = (decided_at IS NULL))),
    CONSTRAINT platform_staff_requests_check1 CHECK (((status = 'pending'::text) = (decided_by IS NULL))),
    CONSTRAINT platform_staff_requests_requested_role_check CHECK ((requested_role = ANY (ARRAY['teacher'::text, 'school_admin'::text]))),
    CONSTRAINT platform_staff_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'declined'::text])))
);


--
-- Name: platform_student_access_intent; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_student_access_intent (
    intent_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    child_id uuid NOT NULL,
    child_principal_id uuid NOT NULL,
    guardian_relationship_id uuid NOT NULL,
    guardian_principal_id uuid NOT NULL,
    email text,
    password_hash text,
    phone_e164 text,
    device_binding text,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    finalized_at timestamp with time zone,
    CONSTRAINT platform_student_access_intent_check CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '00:15:00'::interval)))),
    CONSTRAINT platform_student_access_intent_check1 CHECK ((((status = 'pending'::text) AND (finalized_at IS NULL) AND (email IS NOT NULL) AND (password_hash IS NOT NULL) AND (phone_e164 IS NOT NULL) AND (device_binding IS NOT NULL)) OR ((status = ANY (ARRAY['finalized'::text, 'expired'::text])) AND (finalized_at IS NOT NULL) AND (email IS NULL) AND (password_hash IS NULL) AND (phone_e164 IS NULL) AND (device_binding IS NULL)))),
    CONSTRAINT platform_student_access_intent_check2 CHECK (((finalized_at IS NULL) OR (finalized_at >= created_at))),
    CONSTRAINT platform_student_access_intent_check3 CHECK ((((status = 'finalized'::text) AND (finalized_at <= expires_at)) OR (status = 'pending'::text) OR ((status = 'expired'::text) AND (finalized_at >= expires_at)))),
    CONSTRAINT platform_student_access_intent_device_binding_check CHECK (((device_binding IS NULL) OR (device_binding ~ '^[a-f0-9]{64}$'::text))),
    CONSTRAINT platform_student_access_intent_email_check CHECK (((email IS NULL) OR ((email = lower(email)) AND ((length(email) >= 3) AND (length(email) <= 320)) AND (POSITION(('@'::text) IN (email)) > 1)))),
    CONSTRAINT platform_student_access_intent_password_hash_check CHECK (((password_hash IS NULL) OR ((length(password_hash) >= 1) AND (length(password_hash) <= 1024)))),
    CONSTRAINT platform_student_access_intent_phone_e164_check CHECK (((phone_e164 IS NULL) OR (phone_e164 ~ '^\+[1-9][0-9]{1,14}$'::text))),
    CONSTRAINT platform_student_access_intent_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'finalized'::text, 'expired'::text])))
);


--
-- Name: platform_student_phone_enrollment_intent; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_student_phone_enrollment_intent (
    intent_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    membership_id uuid NOT NULL,
    device_binding text,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT platform_student_phone_enrollment_intent_check CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '00:10:00'::interval)))),
    CONSTRAINT platform_student_phone_enrollment_intent_check1 CHECK ((((status = 'pending'::text) AND (completed_at IS NULL) AND (device_binding IS NOT NULL)) OR ((status = ANY (ARRAY['completed'::text, 'expired'::text])) AND (completed_at IS NOT NULL) AND (device_binding IS NULL)))),
    CONSTRAINT platform_student_phone_enrollment_intent_check2 CHECK (((completed_at IS NULL) OR (completed_at >= created_at))),
    CONSTRAINT platform_student_phone_enrollment_intent_check3 CHECK ((((status = 'completed'::text) AND (completed_at <= expires_at)) OR (status = 'pending'::text) OR ((status = 'expired'::text) AND (completed_at >= expires_at)))),
    CONSTRAINT platform_student_phone_enrollment_intent_device_binding_check CHECK ((device_binding ~ '^[a-f0-9]{64}$'::text)),
    CONSTRAINT platform_student_phone_enrollment_intent_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'expired'::text])))
);


--
-- Name: platform_student_profile_link; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_student_profile_link (
    link_id uuid NOT NULL,
    student_principal_id uuid NOT NULL,
    student_tenant_id uuid NOT NULL,
    family_tenant_id uuid,
    child_id uuid,
    pairing_code_digest text,
    status text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    family_confirmed_at timestamp with time zone,
    student_confirmed_at timestamp with time zone,
    closed_at timestamp with time zone,
    CONSTRAINT platform_student_profile_link_check CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '00:15:00'::interval)))),
    CONSTRAINT platform_student_profile_link_check1 CHECK ((((status = 'pending_family'::text) AND (family_tenant_id IS NULL) AND (child_id IS NULL) AND (pairing_code_digest IS NOT NULL) AND (family_confirmed_at IS NULL) AND (student_confirmed_at IS NULL) AND (closed_at IS NULL)) OR ((status = 'pending_student'::text) AND (family_tenant_id IS NOT NULL) AND (child_id IS NOT NULL) AND (pairing_code_digest IS NULL) AND (family_confirmed_at IS NOT NULL) AND (student_confirmed_at IS NULL) AND (closed_at IS NULL)) OR ((status = 'active'::text) AND (family_tenant_id IS NOT NULL) AND (child_id IS NOT NULL) AND (pairing_code_digest IS NULL) AND (family_confirmed_at IS NOT NULL) AND (student_confirmed_at IS NOT NULL) AND (closed_at IS NULL)) OR ((status = ANY (ARRAY['rejected'::text, 'revoked'::text])) AND (pairing_code_digest IS NULL) AND (closed_at IS NOT NULL)) OR ((status = 'expired'::text) AND (pairing_code_digest IS NULL) AND (closed_at IS NOT NULL) AND (closed_at >= expires_at)))),
    CONSTRAINT platform_student_profile_link_check2 CHECK (((family_confirmed_at IS NULL) OR ((family_confirmed_at >= created_at) AND (family_confirmed_at <= expires_at)))),
    CONSTRAINT platform_student_profile_link_check3 CHECK (((student_confirmed_at IS NULL) OR ((student_confirmed_at >= family_confirmed_at) AND (student_confirmed_at <= expires_at)))),
    CONSTRAINT platform_student_profile_link_check4 CHECK (((closed_at IS NULL) OR (closed_at >= created_at))),
    CONSTRAINT platform_student_profile_link_pairing_code_digest_check CHECK (((pairing_code_digest IS NULL) OR (pairing_code_digest ~ '^[a-f0-9]{64}$'::text))),
    CONSTRAINT platform_student_profile_link_status_check CHECK ((status = ANY (ARRAY['pending_family'::text, 'pending_student'::text, 'active'::text, 'rejected'::text, 'revoked'::text, 'expired'::text])))
);


--
-- Name: platform_student_self_profile; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_student_self_profile (
    profile_id uuid NOT NULL,
    student_principal_id uuid NOT NULL,
    student_tenant_id uuid NOT NULL,
    engine_student_id uuid NOT NULL,
    name text NOT NULL,
    grade smallint NOT NULL,
    locale text NOT NULL,
    preview_notice_version text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT platform_student_self_profile_grade_check CHECK (((grade >= 1) AND (grade <= 11))),
    CONSTRAINT platform_student_self_profile_locale_check CHECK ((locale = ANY (ARRAY['ru'::text, 'kk'::text, 'en'::text]))),
    CONSTRAINT platform_student_self_profile_name_check CHECK (((char_length(name) >= 1) AND (char_length(name) <= 40))),
    CONSTRAINT platform_student_self_profile_preview_notice_version_check CHECK ((preview_notice_version = 'student-self-preview-v1'::text)),
    CONSTRAINT platform_student_self_profile_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);


--
-- Name: platform_teacher_classes; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_teacher_classes (
    principal_id uuid NOT NULL,
    class_id uuid NOT NULL
);


--
-- Name: platform_tests; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_tests (
    id uuid NOT NULL,
    class_id uuid NOT NULL,
    created_by uuid NOT NULL,
    title text NOT NULL,
    topics jsonb NOT NULL,
    count integer NOT NULL,
    starts_at timestamp with time zone NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    duration_seconds integer NOT NULL,
    idempotency_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    kind text DEFAULT 'exam'::text NOT NULL,
    due_at timestamp with time zone,
    CONSTRAINT platform_tests_check CHECK ((ends_at > starts_at)),
    CONSTRAINT platform_tests_count_check CHECK (((count >= 1) AND (count <= 50))),
    CONSTRAINT platform_tests_duration_seconds_check CHECK ((((kind = 'exam'::text) AND ((duration_seconds >= 60) AND (duration_seconds <= 14400))) OR ((kind = 'homework'::text) AND (duration_seconds = 0)))),
    CONSTRAINT platform_tests_kind_due_check CHECK ((((kind = 'exam'::text) AND (due_at IS NULL)) OR ((kind = 'homework'::text) AND (due_at IS NOT NULL))))
);


--
-- Name: platform_trusted_device; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.platform_trusted_device (
    trusted_device_id uuid NOT NULL,
    principal_id uuid NOT NULL,
    token_digest text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT platform_trusted_device_check CHECK ((expires_at > created_at)),
    CONSTRAINT platform_trusted_device_check1 CHECK ((last_seen_at >= created_at)),
    CONSTRAINT platform_trusted_device_check2 CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
    CONSTRAINT platform_trusted_device_token_digest_check CHECK ((token_digest ~ '^[0-9a-f]{64}$'::text))
);


--
-- Name: profile_level_history; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.profile_level_history (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    from_level smallint,
    to_level smallint NOT NULL,
    decision_kind text NOT NULL,
    reason_snapshot jsonb NOT NULL,
    rule_version_id uuid NOT NULL,
    effective_from timestamp with time zone NOT NULL,
    effective_until timestamp with time zone,
    created_by_parent_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_level_history_decision_kind_check CHECK ((decision_kind = ANY (ARRAY['initial'::text, 'automatic_up'::text, 'automatic_down'::text, 'manual_override'::text, 'manual_fixed'::text, 'restored_auto'::text]))),
    CONSTRAINT profile_level_history_from_level_check CHECK (((from_level >= 1) AND (from_level <= 5))),
    CONSTRAINT profile_level_history_to_level_check CHECK (((to_level >= 1) AND (to_level <= 5)))
);


--
-- Name: profile_pauses; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.profile_pauses (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    starts_on date NOT NULL,
    ends_on date,
    reason text,
    created_by_parent_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_pauses_check CHECK (((ends_on IS NULL) OR (ends_on >= starts_on)))
);


--
-- Name: profile_schedules; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.profile_schedules (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    delivery_time time without time zone NOT NULL,
    reminders_enabled boolean DEFAULT true NOT NULL,
    reminder_time time without time zone DEFAULT '18:00:00'::time without time zone NOT NULL,
    weekly_summary_enabled boolean DEFAULT true NOT NULL,
    weekly_summary_dow smallint DEFAULT 0 NOT NULL,
    weekly_summary_time time without time zone DEFAULT '19:00:00'::time without time zone NOT NULL,
    effective_from date NOT NULL,
    effective_to date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profile_schedules_check CHECK (((effective_to IS NULL) OR (effective_to >= effective_from))),
    CONSTRAINT profile_schedules_delivery_time_check CHECK (((delivery_time >= '05:00:00'::time without time zone) AND (delivery_time <= '12:00:00'::time without time zone))),
    CONSTRAINT profile_schedules_weekly_summary_dow_check CHECK ((weekly_summary_dow = 0))
);


--
-- Name: restore_drills; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.restore_drills (
    id uuid NOT NULL,
    backup_run_id uuid NOT NULL,
    environment_kind text NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    recovered_data_cutoff_at timestamp with time zone,
    rpo_seconds integer,
    rto_seconds integer,
    schema_restore_verified boolean DEFAULT false NOT NULL,
    artifact_manifest_verified boolean DEFAULT false NOT NULL,
    key_recovery_verified boolean DEFAULT false NOT NULL,
    smoke_verified boolean DEFAULT false NOT NULL,
    outcome text NOT NULL,
    evidence_checksum character(64),
    safe_error_code character varying(64),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT restore_drills_check CHECK (((outcome <> 'succeeded'::text) OR ((finished_at IS NOT NULL) AND (recovered_data_cutoff_at IS NOT NULL) AND (rpo_seconds IS NOT NULL) AND (rto_seconds IS NOT NULL) AND schema_restore_verified AND artifact_manifest_verified AND key_recovery_verified AND smoke_verified AND (evidence_checksum IS NOT NULL)))),
    CONSTRAINT restore_drills_environment_kind_check CHECK ((environment_kind = ANY (ARRAY['sanitized'::text, 'isolated'::text]))),
    CONSTRAINT restore_drills_outcome_check CHECK ((outcome = ANY (ARRAY['running'::text, 'succeeded'::text, 'failed'::text]))),
    CONSTRAINT restore_drills_rpo_seconds_check CHECK (((rpo_seconds >= 0) AND (rpo_seconds <= 86400))),
    CONSTRAINT restore_drills_rto_seconds_check CHECK (((rto_seconds >= 0) AND (rto_seconds <= 14400)))
);


--
-- Name: retake_authorizations; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.retake_authorizations (
    id uuid NOT NULL,
    pack_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    authorized_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    consumed_at timestamp with time zone,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT retake_authorizations_check CHECK ((expires_at > authorized_at))
);


--
-- Name: retention_runs; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.retention_runs (
    id uuid NOT NULL,
    policy_version character varying(64) NOT NULL,
    data_class text NOT NULL,
    cutoff_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone,
    deleted_count bigint DEFAULT 0 NOT NULL,
    outcome text NOT NULL,
    safe_error_code character varying(64),
    correlation_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT retention_runs_data_class_check CHECK ((data_class = ANY (ARRAY['operation_events'::text, 'job_attempts'::text]))),
    CONSTRAINT retention_runs_deleted_count_check CHECK ((deleted_count >= 0)),
    CONSTRAINT retention_runs_outcome_check CHECK ((outcome = ANY (ARRAY['succeeded'::text, 'failed'::text])))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.schema_migrations (
    version character varying(64) NOT NULL,
    checksum character(64) NOT NULL,
    applied_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_by character varying(80) NOT NULL
);


--
-- Name: skill_event_exclusions; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.skill_event_exclusions (
    id uuid NOT NULL,
    skill_event_id uuid NOT NULL,
    reason text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT skill_event_exclusions_reason_check CHECK ((reason = ANY (ARRAY['content_voided'::text, 'parent_assistance'::text, 'superseded_score'::text])))
);


--
-- Name: skill_events; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.skill_events (
    id uuid NOT NULL,
    profile_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    pack_item_id uuid NOT NULL,
    attempt_id uuid NOT NULL,
    attempt_answer_id uuid NOT NULL,
    score_revision_id uuid NOT NULL,
    event_role text NOT NULL,
    evidence_scope text NOT NULL,
    outcome text NOT NULL,
    difficulty_level smallint NOT NULL,
    category text NOT NULL,
    base_weight numeric(4,2) NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    rule_version_id uuid NOT NULL,
    skill_role text NOT NULL,
    contributes_to_topic_selection boolean NOT NULL,
    contributes_to_status boolean NOT NULL,
    contributes_to_auto_level boolean NOT NULL,
    CONSTRAINT skill_events_base_weight_check CHECK ((base_weight > (0)::numeric)),
    CONSTRAINT skill_events_diagnostic_contribution_ck CHECK ((((skill_role = 'primary'::text) AND (outcome = ANY (ARRAY['correct'::text, 'incorrect'::text])) AND (evidence_scope = 'mastery'::text)) OR ((evidence_scope = 'diagnostic'::text) AND (NOT contributes_to_topic_selection) AND (NOT contributes_to_status) AND (NOT contributes_to_auto_level)))),
    CONSTRAINT skill_events_difficulty_level_check CHECK (((difficulty_level >= 1) AND (difficulty_level <= 5))),
    CONSTRAINT skill_events_event_role_check CHECK ((event_role = ANY (ARRAY['initial'::text, 'retake'::text]))),
    CONSTRAINT skill_events_evidence_scope_check CHECK ((evidence_scope = ANY (ARRAY['mastery'::text, 'diagnostic'::text]))),
    CONSTRAINT skill_events_outcome_check CHECK ((outcome = ANY (ARRAY['correct'::text, 'incorrect'::text, 'skipped'::text]))),
    CONSTRAINT skill_events_skill_role_ck CHECK ((skill_role = ANY (ARRAY['primary'::text, 'secondary'::text])))
);


--
-- Name: skill_prerequisites; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.skill_prerequisites (
    skill_id uuid NOT NULL,
    prerequisite_skill_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT skill_prerequisites_check CHECK ((skill_id <> prerequisite_skill_id))
);


--
-- Name: skills; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.skills (
    id uuid NOT NULL,
    topic_id uuid NOT NULL,
    code character varying(100) NOT NULL,
    name text NOT NULL,
    observable_action text NOT NULL,
    min_difficulty smallint NOT NULL,
    max_difficulty smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT skills_check CHECK (((max_difficulty >= 1) AND (max_difficulty <= 5) AND (max_difficulty >= min_difficulty))),
    CONSTRAINT skills_min_difficulty_check CHECK (((min_difficulty >= 1) AND (min_difficulty <= 5)))
);


--
-- Name: slo_daily_aggregates; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.slo_daily_aggregates (
    local_date date NOT NULL,
    operation_kind text NOT NULL,
    policy_version character varying(64) NOT NULL,
    eligible_count bigint NOT NULL,
    successful_count bigint NOT NULL,
    failed_count bigint NOT NULL,
    measurement_window_seconds integer NOT NULL,
    approved_maintenance_seconds integer DEFAULT 0 NOT NULL,
    telegram_excluded_seconds integer DEFAULT 0 NOT NULL,
    provider_outage_seconds integer DEFAULT 0 NOT NULL,
    unavailable_seconds integer DEFAULT 0 NOT NULL,
    source_hash character(64) NOT NULL,
    calculated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT slo_daily_aggregates_approved_maintenance_seconds_check CHECK ((approved_maintenance_seconds >= 0)),
    CONSTRAINT slo_daily_aggregates_check CHECK (((successful_count + failed_count) <= eligible_count)),
    CONSTRAINT slo_daily_aggregates_check1 CHECK ((approved_maintenance_seconds <= measurement_window_seconds)),
    CONSTRAINT slo_daily_aggregates_check2 CHECK ((telegram_excluded_seconds <= measurement_window_seconds)),
    CONSTRAINT slo_daily_aggregates_check3 CHECK ((provider_outage_seconds <= unavailable_seconds)),
    CONSTRAINT slo_daily_aggregates_check4 CHECK ((unavailable_seconds <= measurement_window_seconds)),
    CONSTRAINT slo_daily_aggregates_eligible_count_check CHECK ((eligible_count >= 0)),
    CONSTRAINT slo_daily_aggregates_failed_count_check CHECK ((failed_count >= 0)),
    CONSTRAINT slo_daily_aggregates_measurement_window_seconds_check CHECK ((measurement_window_seconds >= 0)),
    CONSTRAINT slo_daily_aggregates_operation_kind_check CHECK ((operation_kind = ANY (ARRAY['capability_get'::text, 'capability_submit'::text, 'telegram_command'::text]))),
    CONSTRAINT slo_daily_aggregates_provider_outage_seconds_check CHECK ((provider_outage_seconds >= 0)),
    CONSTRAINT slo_daily_aggregates_successful_count_check CHECK ((successful_count >= 0)),
    CONSTRAINT slo_daily_aggregates_telegram_excluded_seconds_check CHECK ((telegram_excluded_seconds >= 0)),
    CONSTRAINT slo_daily_aggregates_unavailable_seconds_check CHECK ((unavailable_seconds >= 0))
);


--
-- Name: telegram_delivery_attempts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.telegram_delivery_attempts (
    id uuid NOT NULL,
    job_id uuid NOT NULL,
    pack_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    delivery_kind text NOT NULL,
    initial_retry_no smallint,
    parent_command_id uuid,
    telegram_message_id bigint,
    outcome text NOT NULL,
    provider_code character varying(64),
    attempted_at timestamp with time zone DEFAULT now() NOT NULL,
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT telegram_delivery_attempts_delivery_kind_check CHECK ((delivery_kind = ANY (ARRAY['initial_retry'::text, 'manual_resend'::text]))),
    CONSTRAINT telegram_delivery_attempts_initial_retry_no_check CHECK (((initial_retry_no >= 1) AND (initial_retry_no <= 3))),
    CONSTRAINT telegram_delivery_attempts_outcome_check CHECK ((outcome = ANY (ARRAY['pending'::text, 'accepted'::text, 'failed'::text])))
);


--
-- Name: telegram_update_receipts; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.telegram_update_receipts (
    telegram_update_id bigint NOT NULL,
    parent_id uuid,
    command_id uuid NOT NULL,
    command_type character varying(64) NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    processed_at timestamp with time zone,
    outcome text DEFAULT 'accepted'::text NOT NULL,
    correlation_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT telegram_update_receipts_outcome_check CHECK ((outcome = ANY (ARRAY['accepted'::text, 'applied'::text, 'rejected'::text, 'failed'::text])))
);


--
-- Name: topics; Type: TABLE; Schema: mathprep; Owner: -
--

CREATE TABLE mathprep.topics (
    id uuid NOT NULL,
    curriculum_version_id uuid NOT NULL,
    code character varying(80) NOT NULL,
    name text NOT NULL,
    grade_level smallint NOT NULL,
    quarter smallint NOT NULL,
    sequence_no smallint NOT NULL,
    kind text NOT NULL,
    language_code character varying(8) DEFAULT 'ru'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT topics_grade_level_check CHECK (((grade_level >= 1) AND (grade_level <= 11))),
    CONSTRAINT topics_kind_check CHECK ((kind = ANY (ARRAY['school'::text, 'olympiad'::text]))),
    CONSTRAINT topics_language_code_ck CHECK (((language_code)::text = ANY (ARRAY[('ru'::character varying)::text, ('kk'::character varying)::text]))),
    CONSTRAINT topics_quarter_check CHECK (((quarter >= 1) AND (quarter <= 4))),
    CONSTRAINT topics_sequence_no_check CHECK ((sequence_no > 0))
);


--
-- Name: answer_widget; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.answer_widget (
    code text NOT NULL
);


--
-- Name: billing_order; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_order (
    order_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    actor_principal_id uuid NOT NULL,
    idempotency_key text NOT NULL,
    currency text DEFAULT 'KZT'::text NOT NULL,
    amount_kzt numeric(12,2) NOT NULL,
    status text DEFAULT 'PENDING'::text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    paid_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    CONSTRAINT billing_order_amount_kzt_check CHECK ((amount_kzt > (0)::numeric)),
    CONSTRAINT billing_order_check CHECK ((updated_at >= created_at)),
    CONSTRAINT billing_order_check1 CHECK (((paid_at IS NULL) OR (paid_at >= created_at))),
    CONSTRAINT billing_order_check2 CHECK (((cancelled_at IS NULL) OR (cancelled_at >= created_at))),
    CONSTRAINT billing_order_check3 CHECK ((((status = 'PENDING'::text) AND (paid_at IS NULL) AND (cancelled_at IS NULL)) OR ((status = 'PAID'::text) AND (paid_at IS NOT NULL) AND (cancelled_at IS NULL)) OR ((status = 'CANCELLED'::text) AND (paid_at IS NULL) AND (cancelled_at IS NOT NULL)))),
    CONSTRAINT billing_order_currency_check CHECK ((currency = 'KZT'::text)),
    CONSTRAINT billing_order_idempotency_key_check CHECK ((length(btrim(idempotency_key)) > 0)),
    CONSTRAINT billing_order_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'PAID'::text, 'CANCELLED'::text])))
);


--
-- Name: billing_order_child; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_order_child (
    order_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    child_profile_id uuid NOT NULL,
    amount_kzt numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT billing_order_child_amount_kzt_check CHECK ((amount_kzt > (0)::numeric))
);


--
-- Name: cas_evaluation_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_evaluation_request (
    request_id uuid NOT NULL,
    requester_id uuid NOT NULL,
    session_id text NOT NULL,
    operation_type text NOT NULL,
    candidate_expression text NOT NULL,
    reference_expression text NOT NULL,
    policy_json jsonb NOT NULL,
    status text NOT NULL,
    verdict text,
    reason_code text,
    result_json jsonb,
    created_at timestamp with time zone NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    lease_expires_at timestamp with time zone,
    heartbeat_at timestamp with time zone,
    wall_deadline_at timestamp with time zone NOT NULL,
    attempt_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT cas_evaluation_request_attempt_count_check CHECK (((attempt_count >= 0) AND (attempt_count <= 10))),
    CONSTRAINT cas_evaluation_request_candidate_expression_check CHECK (((octet_length(candidate_expression) >= 1) AND (octet_length(candidate_expression) <= 8192))),
    CONSTRAINT cas_evaluation_request_check CHECK ((wall_deadline_at > created_at)),
    CONSTRAINT cas_evaluation_request_lifecycle_check CHECK ((((status = 'PENDING'::text) AND (started_at IS NULL) AND (completed_at IS NULL) AND (lease_expires_at IS NULL) AND (heartbeat_at IS NULL) AND (verdict IS NULL) AND (reason_code IS NULL) AND (result_json IS NULL)) OR ((status = 'IN_PROGRESS'::text) AND (started_at IS NOT NULL) AND (completed_at IS NULL) AND (lease_expires_at IS NOT NULL) AND (heartbeat_at IS NOT NULL) AND (verdict IS NULL) AND (reason_code IS NULL) AND (result_json IS NULL)) OR ((status = ANY (ARRAY['DONE'::text, 'FAILED'::text])) AND (started_at IS NOT NULL) AND (completed_at IS NOT NULL) AND (verdict IS NOT NULL) AND (reason_code IS NOT NULL)))),
    CONSTRAINT cas_evaluation_request_policy_json_check CHECK (((octet_length((policy_json)::text) <= 16384) AND (jsonb_typeof(policy_json) = 'object'::text) AND (policy_json ? 'allowed_symbols'::text) AND (jsonb_typeof((policy_json -> 'allowed_symbols'::text)) = 'array'::text) AND (policy_json ? 'allowed_functions'::text) AND (jsonb_typeof((policy_json -> 'allowed_functions'::text)) = 'array'::text) AND (policy_json ? 'limits'::text) AND (jsonb_typeof((policy_json -> 'limits'::text)) = 'object'::text))),
    CONSTRAINT cas_evaluation_request_reference_expression_check CHECK (((octet_length(reference_expression) >= 1) AND (octet_length(reference_expression) <= 8192))),
    CONSTRAINT cas_evaluation_request_result_json_check CHECK (((result_json IS NULL) OR ((octet_length((result_json)::text) <= 65536) AND (jsonb_typeof(result_json) = 'object'::text)))),
    CONSTRAINT cas_evaluation_request_session_id_check CHECK (((octet_length(session_id) >= 1) AND (octet_length(session_id) <= 128))),
    CONSTRAINT cas_evaluation_request_timeout_verdict_check CHECK (((reason_code IS DISTINCT FROM 'CAS_TIMEOUT'::text) OR (verdict = 'UNPARSEABLE'::text)))
);


--
-- Name: cas_evaluation_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_evaluation_status (
    code text NOT NULL
);


--
-- Name: cas_operation_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_operation_type (
    code text NOT NULL
);


--
-- Name: cas_submission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_submission (
    submission_id uuid NOT NULL,
    item_id uuid NOT NULL,
    student_id uuid NOT NULL,
    idempotency_key text NOT NULL,
    submitted_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: child_entitlement_period; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.child_entitlement_period (
    entitlement_period_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    child_profile_id uuid NOT NULL,
    order_id uuid NOT NULL,
    period_starts_at timestamp with time zone NOT NULL,
    period_ends_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    CONSTRAINT child_entitlement_period_check CHECK ((period_ends_at > period_starts_at)),
    CONSTRAINT child_entitlement_period_check1 CHECK ((created_at <= period_starts_at))
);


--
-- Name: domain; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domain (
    code text NOT NULL
);


--
-- Name: equivalence_policy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equivalence_policy (
    code text NOT NULL
);


--
-- Name: event_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_log (
    event_id uuid NOT NULL,
    event_type text NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    payload_json jsonb NOT NULL
);


--
-- Name: event_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.event_type (
    code text NOT NULL
);


--
-- Name: generation_mode; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation_mode (
    code text NOT NULL
);


--
-- Name: generation_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generation_request (
    request_id uuid NOT NULL,
    student_id uuid NOT NULL,
    grade integer NOT NULL,
    topics jsonb NOT NULL,
    count integer NOT NULL,
    status text NOT NULL,
    idempotency_key text NOT NULL,
    lease_expires_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    locale text DEFAULT 'ru-KZ'::text NOT NULL,
    CONSTRAINT generation_request_count_check CHECK ((count > 0)),
    CONSTRAINT generation_request_locale_check CHECK ((locale = ANY (ARRAY['ru-KZ'::text, 'kk-KZ'::text, 'en-US'::text]))),
    CONSTRAINT generation_request_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'IN_PROGRESS'::text, 'DONE'::text, 'FAILED'::text])))
);


--
-- Name: COLUMN generation_request.locale; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.generation_request.locale IS 'Persisted request locale preference; generated task locale is frozen on task_instance.locale.';


--
-- Name: grade_band; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grade_band (
    code text NOT NULL
);


--
-- Name: locale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locale (
    code text NOT NULL
);


--
-- Name: mastery_topic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mastery_topic (
    student_id uuid NOT NULL,
    domain text NOT NULL,
    tier text NOT NULL,
    ema_score double precision NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    evidence_count bigint DEFAULT 1 NOT NULL,
    CONSTRAINT mastery_topic_evidence_count_nonnegative CHECK ((evidence_count >= 0))
);


--
-- Name: payment_attempt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_attempt (
    payment_attempt_id uuid NOT NULL,
    order_id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    provider_code text NOT NULL,
    attempt_number integer NOT NULL,
    idempotency_key text NOT NULL,
    provider_invoice_id text,
    provider_payment_id text,
    currency text DEFAULT 'KZT'::text NOT NULL,
    amount_kzt numeric(12,2) NOT NULL,
    status text DEFAULT 'CREATED'::text NOT NULL,
    callback_secret_hash_sha256 bytea,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    updated_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    completed_at timestamp with time zone,
    CONSTRAINT payment_attempt_amount_kzt_check CHECK ((amount_kzt > (0)::numeric)),
    CONSTRAINT payment_attempt_attempt_number_check CHECK ((attempt_number > 0)),
    CONSTRAINT payment_attempt_callback_secret_hash_sha256_check CHECK (((callback_secret_hash_sha256 IS NULL) OR (octet_length(callback_secret_hash_sha256) = 32))),
    CONSTRAINT payment_attempt_check CHECK ((updated_at >= created_at)),
    CONSTRAINT payment_attempt_check1 CHECK (((completed_at IS NULL) OR (completed_at >= created_at))),
    CONSTRAINT payment_attempt_check2 CHECK ((((status = ANY (ARRAY['CREATED'::text, 'PENDING'::text])) AND (completed_at IS NULL)) OR ((status = ANY (ARRAY['SUCCEEDED'::text, 'FAILED'::text, 'CANCELLED'::text])) AND (completed_at IS NOT NULL)))),
    CONSTRAINT payment_attempt_currency_check CHECK ((currency = 'KZT'::text)),
    CONSTRAINT payment_attempt_idempotency_key_check CHECK ((length(btrim(idempotency_key)) > 0)),
    CONSTRAINT payment_attempt_provider_code_check CHECK ((length(btrim(provider_code)) > 0)),
    CONSTRAINT payment_attempt_status_check CHECK ((status = ANY (ARRAY['CREATED'::text, 'PENDING'::text, 'SUCCEEDED'::text, 'FAILED'::text, 'CANCELLED'::text])))
);


--
-- Name: reason_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reason_code (
    code text NOT NULL
);


--
-- Name: render_target; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.render_target (
    code text NOT NULL
);


--
-- Name: students; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.students (
    user_id uuid NOT NULL,
    grade integer NOT NULL
);


--
-- Name: submission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.submission (
    submission_id uuid NOT NULL,
    item_id uuid NOT NULL,
    student_id uuid NOT NULL,
    raw_input text NOT NULL,
    verdict text NOT NULL,
    reason_code text NOT NULL,
    attempt_index integer NOT NULL,
    submitted_at timestamp with time zone NOT NULL,
    idempotency_key text NOT NULL,
    CONSTRAINT submission_attempt_index_check CHECK ((attempt_index >= 0))
);


--
-- Name: task_instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_instance (
    item_id uuid NOT NULL,
    type_id text NOT NULL,
    spec_version text NOT NULL,
    tier text NOT NULL,
    locale text NOT NULL,
    render_target text NOT NULL,
    seed bigint NOT NULL,
    params_json jsonb NOT NULL,
    problem_text text NOT NULL,
    correct_answer_json jsonb NOT NULL,
    task_set_id uuid NOT NULL
);


--
-- Name: task_set; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_set (
    task_set_id uuid NOT NULL,
    student_id uuid NOT NULL,
    request_id uuid NOT NULL,
    issued_at timestamp with time zone NOT NULL,
    idempotency_key text NOT NULL
);


--
-- Name: task_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_type (
    type_id text NOT NULL,
    domain text NOT NULL,
    grade text NOT NULL,
    spec_version text NOT NULL,
    generation_mode text NOT NULL,
    status text NOT NULL,
    equivalence_policy text NOT NULL,
    validation_method text NOT NULL,
    locale text NOT NULL,
    answer_widget text NOT NULL,
    widget_config jsonb
);


--
-- Name: task_type_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_type_status (
    code text NOT NULL
);


--
-- Name: task_type_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.task_type_template (
    type_id text NOT NULL,
    locale text NOT NULL,
    template_text text NOT NULL,
    spec_version text NOT NULL,
    render_target text NOT NULL,
    CONSTRAINT task_type_template_template_text_check CHECK (((octet_length(template_text) >= 1) AND (octet_length(template_text) <= 8192)))
);


--
-- Name: tier_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tier_code (
    code text NOT NULL
);


--
-- Name: user_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_type (
    code text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id uuid NOT NULL,
    user_type text NOT NULL
);


--
-- Name: validation_method; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.validation_method (
    code text NOT NULL
);


--
-- Name: verdict; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verdict (
    code text NOT NULL
);


--
-- Name: verified_provider_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verified_provider_event (
    verified_provider_event_id uuid NOT NULL,
    provider_code text NOT NULL,
    provider_event_id text NOT NULL,
    payment_attempt_id uuid,
    body_sha256 bytea NOT NULL,
    status text DEFAULT 'VERIFIED'::text NOT NULL,
    verified_at timestamp with time zone NOT NULL,
    received_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    processed_at timestamp with time zone,
    CONSTRAINT verified_provider_event_body_sha256_check CHECK ((octet_length(body_sha256) = 32)),
    CONSTRAINT verified_provider_event_check CHECK ((verified_at <= received_at)),
    CONSTRAINT verified_provider_event_check1 CHECK (((processed_at IS NULL) OR (processed_at >= received_at))),
    CONSTRAINT verified_provider_event_check2 CHECK ((((status = 'VERIFIED'::text) AND (processed_at IS NULL)) OR ((status = ANY (ARRAY['APPLIED'::text, 'IGNORED'::text])) AND (processed_at IS NOT NULL)))),
    CONSTRAINT verified_provider_event_provider_code_check CHECK ((length(btrim(provider_code)) > 0)),
    CONSTRAINT verified_provider_event_provider_event_id_check CHECK ((length(btrim(provider_event_id)) > 0)),
    CONSTRAINT verified_provider_event_status_check CHECK ((status = ANY (ARRAY['VERIFIED'::text, 'APPLIED'::text, 'IGNORED'::text])))
);


--
-- Name: access_audit_events access_audit_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_audit_events
    ADD CONSTRAINT access_audit_events_pkey PRIMARY KEY (id);


--
-- Name: access_consents access_consents_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_consents
    ADD CONSTRAINT access_consents_pkey PRIMARY KEY (id);


--
-- Name: access_external_identities access_external_identities_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_external_identities
    ADD CONSTRAINT access_external_identities_pkey PRIMARY KEY (id);


--
-- Name: access_external_identities access_external_identities_provider_subject_ref_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_external_identities
    ADD CONSTRAINT access_external_identities_provider_subject_ref_key UNIQUE (provider, subject_ref);


--
-- Name: access_guardian_relationships access_guardian_relationships_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_guardian_relationships
    ADD CONSTRAINT access_guardian_relationships_pkey PRIMARY KEY (id);


--
-- Name: access_guardian_relationships access_guardian_relationships_tenant_id_guardian_principal__key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_guardian_relationships
    ADD CONSTRAINT access_guardian_relationships_tenant_id_guardian_principal__key UNIQUE (tenant_id, guardian_principal_id, learner_id);


--
-- Name: access_invitations access_invitations_nonce_hash_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_invitations
    ADD CONSTRAINT access_invitations_nonce_hash_key UNIQUE (nonce_hash);


--
-- Name: access_invitations access_invitations_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_invitations
    ADD CONSTRAINT access_invitations_pkey PRIMARY KEY (id);


--
-- Name: access_invitations access_invitations_tenant_id_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_invitations
    ADD CONSTRAINT access_invitations_tenant_id_idempotency_key_key UNIQUE (tenant_id, idempotency_key);


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_pkey PRIMARY KEY (parent_id);


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_principal_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_principal_id_key UNIQUE (principal_id);


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_tenant_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_tenant_id_key UNIQUE (tenant_id);


--
-- Name: access_memberships access_memberships_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_memberships
    ADD CONSTRAINT access_memberships_pkey PRIMARY KEY (id);


--
-- Name: access_memberships access_memberships_tenant_id_principal_id_role_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_memberships
    ADD CONSTRAINT access_memberships_tenant_id_principal_id_role_key UNIQUE (tenant_id, principal_id, role);


--
-- Name: access_principals access_principals_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_principals
    ADD CONSTRAINT access_principals_pkey PRIMARY KEY (id);


--
-- Name: access_recovery_cases access_recovery_cases_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_recovery_cases
    ADD CONSTRAINT access_recovery_cases_pkey PRIMARY KEY (id);


--
-- Name: access_tenants access_tenants_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_tenants
    ADD CONSTRAINT access_tenants_pkey PRIMARY KEY (id);


--
-- Name: adaptation_rule_versions adaptation_rule_versions_config_hash_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.adaptation_rule_versions
    ADD CONSTRAINT adaptation_rule_versions_config_hash_key UNIQUE (config_hash);


--
-- Name: adaptation_rule_versions adaptation_rule_versions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.adaptation_rule_versions
    ADD CONSTRAINT adaptation_rule_versions_pkey PRIMARY KEY (id);


--
-- Name: adaptation_rule_versions adaptation_rule_versions_semantic_version_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.adaptation_rule_versions
    ADD CONSTRAINT adaptation_rule_versions_semantic_version_key UNIQUE (semantic_version);


--
-- Name: answer_evaluation_revisions answer_evaluation_revisions_attempt_answer_id_score_revisio_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.answer_evaluation_revisions
    ADD CONSTRAINT answer_evaluation_revisions_attempt_answer_id_score_revisio_key UNIQUE (attempt_answer_id, score_revision_id);


--
-- Name: answer_evaluation_revisions answer_evaluation_revisions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.answer_evaluation_revisions
    ADD CONSTRAINT answer_evaluation_revisions_pkey PRIMARY KEY (id);


--
-- Name: assistance_marks assistance_marks_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.assistance_marks
    ADD CONSTRAINT assistance_marks_pkey PRIMARY KEY (id);


--
-- Name: attempt_answers attempt_answers_attempt_id_pack_item_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_answers
    ADD CONSTRAINT attempt_answers_attempt_id_pack_item_id_key UNIQUE (attempt_id, pack_item_id);


--
-- Name: attempt_answers attempt_answers_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_answers
    ADD CONSTRAINT attempt_answers_pkey PRIMARY KEY (id);


--
-- Name: attempt_score_revisions attempt_score_revisions_attempt_id_revision_no_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_score_revisions
    ADD CONSTRAINT attempt_score_revisions_attempt_id_revision_no_key UNIQUE (attempt_id, revision_no);


--
-- Name: attempt_score_revisions attempt_score_revisions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_score_revisions
    ADD CONSTRAINT attempt_score_revisions_pkey PRIMARY KEY (id);


--
-- Name: attempts attempts_id_pack_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempts
    ADD CONSTRAINT attempts_id_pack_id_key UNIQUE (id, pack_id);


--
-- Name: attempts attempts_pack_id_attempt_no_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempts
    ADD CONSTRAINT attempts_pack_id_attempt_no_key UNIQUE (pack_id, attempt_no);


--
-- Name: attempts attempts_pack_id_submission_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempts
    ADD CONSTRAINT attempts_pack_id_submission_idempotency_key_key UNIQUE (pack_id, submission_idempotency_key);


--
-- Name: attempts attempts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempts
    ADD CONSTRAINT attempts_pkey PRIMARY KEY (id);


--
-- Name: backup_artifact_manifests backup_artifact_manifests_backup_run_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.backup_artifact_manifests
    ADD CONSTRAINT backup_artifact_manifests_backup_run_id_key UNIQUE (backup_run_id);


--
-- Name: backup_artifact_manifests backup_artifact_manifests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.backup_artifact_manifests
    ADD CONSTRAINT backup_artifact_manifests_pkey PRIMARY KEY (id);


--
-- Name: backup_runs backup_runs_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.backup_runs
    ADD CONSTRAINT backup_runs_pkey PRIMARY KEY (id);


--
-- Name: content_decision_events content_decision_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_decision_events
    ADD CONSTRAINT content_decision_events_pkey PRIMARY KEY (id);


--
-- Name: content_incident_pack_items content_incident_pack_items_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incident_pack_items
    ADD CONSTRAINT content_incident_pack_items_pkey PRIMARY KEY (incident_id, pack_item_id);


--
-- Name: content_incidents content_incidents_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incidents
    ADD CONSTRAINT content_incidents_pkey PRIMARY KEY (id);


--
-- Name: content_readiness_run_days content_readiness_run_days_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_run_days
    ADD CONSTRAINT content_readiness_run_days_pkey PRIMARY KEY (run_id, simulation_date);


--
-- Name: content_readiness_runs content_readiness_runs_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_runs
    ADD CONSTRAINT content_readiness_runs_pkey PRIMARY KEY (id);


--
-- Name: content_reports content_reports_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_reports
    ADD CONSTRAINT content_reports_pkey PRIMARY KEY (id);


--
-- Name: curriculum_versions curriculum_versions_code_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.curriculum_versions
    ADD CONSTRAINT curriculum_versions_code_key UNIQUE (code);


--
-- Name: curriculum_versions curriculum_versions_id_language_uq; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.curriculum_versions
    ADD CONSTRAINT curriculum_versions_id_language_uq UNIQUE (id, language_code);


--
-- Name: curriculum_versions curriculum_versions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.curriculum_versions
    ADD CONSTRAINT curriculum_versions_pkey PRIMARY KEY (id);


--
-- Name: deletion_requests deletion_requests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.deletion_requests
    ADD CONSTRAINT deletion_requests_pkey PRIMARY KEY (id);


--
-- Name: difficulty_override_events difficulty_override_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_pkey PRIMARY KEY (id);


--
-- Name: difficulty_overrides difficulty_overrides_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_overrides
    ADD CONSTRAINT difficulty_overrides_pkey PRIMARY KEY (id);


--
-- Name: item_instances item_instances_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_instances
    ADD CONSTRAINT item_instances_pkey PRIMARY KEY (id);


--
-- Name: item_version_skills item_version_skills_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_version_skills
    ADD CONSTRAINT item_version_skills_pkey PRIMARY KEY (item_version_id, skill_id);


--
-- Name: item_versions item_versions_content_hash_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_versions
    ADD CONSTRAINT item_versions_content_hash_key UNIQUE (content_hash);


--
-- Name: item_versions item_versions_item_id_version_no_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_versions
    ADD CONSTRAINT item_versions_item_id_version_no_key UNIQUE (item_id, version_no);


--
-- Name: item_versions item_versions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_versions
    ADD CONSTRAINT item_versions_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: items items_stable_code_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.items
    ADD CONSTRAINT items_stable_code_key UNIQUE (stable_code);


--
-- Name: job_attempts job_attempts_job_id_attempt_no_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.job_attempts
    ADD CONSTRAINT job_attempts_job_id_attempt_no_key UNIQUE (job_id, attempt_no);


--
-- Name: job_attempts job_attempts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.job_attempts
    ADD CONSTRAINT job_attempts_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_dedupe_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.jobs
    ADD CONSTRAINT jobs_dedupe_key_key UNIQUE (dedupe_key);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: learner_profiles learner_profiles_id_parent_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_id_parent_id_key UNIQUE (id, parent_id);


--
-- Name: learner_profiles learner_profiles_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_pkey PRIMARY KEY (id);


--
-- Name: learner_skill_projection learner_skill_projection_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_skill_projection
    ADD CONSTRAINT learner_skill_projection_pkey PRIMARY KEY (profile_id, skill_id);


--
-- Name: learners learners_id_parent_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learners
    ADD CONSTRAINT learners_id_parent_id_key UNIQUE (id, parent_id);


--
-- Name: learners learners_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learners
    ADD CONSTRAINT learners_pkey PRIMARY KEY (id);


--
-- Name: operation_events operation_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.operation_events
    ADD CONSTRAINT operation_events_pkey PRIMARY KEY (id);


--
-- Name: pack_access_tokens pack_access_tokens_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_access_tokens
    ADD CONSTRAINT pack_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: pack_access_tokens pack_access_tokens_token_hash_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_access_tokens
    ADD CONSTRAINT pack_access_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: pack_artifacts pack_artifacts_object_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_artifacts
    ADD CONSTRAINT pack_artifacts_object_key_key UNIQUE (object_key);


--
-- Name: pack_artifacts pack_artifacts_pack_id_artifact_kind_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_artifacts
    ADD CONSTRAINT pack_artifacts_pack_id_artifact_kind_key UNIQUE (pack_id, artifact_kind);


--
-- Name: pack_artifacts pack_artifacts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_artifacts
    ADD CONSTRAINT pack_artifacts_pkey PRIMARY KEY (id);


--
-- Name: pack_item_skills pack_item_skills_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_skills
    ADD CONSTRAINT pack_item_skills_pkey PRIMARY KEY (pack_item_id, skill_id);


--
-- Name: pack_item_voids pack_item_voids_incident_id_pack_item_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_voids
    ADD CONSTRAINT pack_item_voids_incident_id_pack_item_id_key UNIQUE (incident_id, pack_item_id);


--
-- Name: pack_item_voids pack_item_voids_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_voids
    ADD CONSTRAINT pack_item_voids_pkey PRIMARY KEY (pack_item_id);


--
-- Name: pack_items pack_items_id_pack_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_id_pack_id_key UNIQUE (id, pack_id);


--
-- Name: pack_items pack_items_pack_id_position_no_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_pack_id_position_no_key UNIQUE (pack_id, position_no);


--
-- Name: pack_items pack_items_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_pkey PRIMARY KEY (id);


--
-- Name: pack_lifecycle_events pack_lifecycle_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_lifecycle_events
    ADD CONSTRAINT pack_lifecycle_events_pkey PRIMARY KEY (id);


--
-- Name: packs packs_id_parent_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_id_parent_id_key UNIQUE (id, parent_id);


--
-- Name: packs packs_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_pkey PRIMARY KEY (id);


--
-- Name: packs packs_profile_id_local_date_pack_type_additional_ordinal_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_profile_id_local_date_pack_type_additional_ordinal_key UNIQUE (profile_id, local_date, pack_type, additional_ordinal);


--
-- Name: packs packs_profile_id_origin_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_profile_id_origin_idempotency_key_key UNIQUE (profile_id, origin_idempotency_key);


--
-- Name: parent_active_profiles parent_active_profiles_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_active_profiles
    ADD CONSTRAINT parent_active_profiles_pkey PRIMARY KEY (parent_id);


--
-- Name: parent_command_receipts parent_command_receipts_parent_id_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_command_receipts
    ADD CONSTRAINT parent_command_receipts_parent_id_idempotency_key_key UNIQUE (parent_id, idempotency_key);


--
-- Name: parent_command_receipts parent_command_receipts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_command_receipts
    ADD CONSTRAINT parent_command_receipts_pkey PRIMARY KEY (command_id);


--
-- Name: parent_consents parent_consents_parent_id_consent_kind_policy_version_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_consents
    ADD CONSTRAINT parent_consents_parent_id_consent_kind_policy_version_key UNIQUE (parent_id, consent_kind, policy_version);


--
-- Name: parent_consents parent_consents_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_consents
    ADD CONSTRAINT parent_consents_pkey PRIMARY KEY (id);


--
-- Name: parents parents_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parents
    ADD CONSTRAINT parents_pkey PRIMARY KEY (id);


--
-- Name: parents parents_telegram_user_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parents
    ADD CONSTRAINT parents_telegram_user_id_key UNIQUE (telegram_user_id);


--
-- Name: phone_identity phone_identity_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.phone_identity
    ADD CONSTRAINT phone_identity_pkey PRIMARY KEY (phone_identity_id);


--
-- Name: platform_accounts platform_accounts_email_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_accounts
    ADD CONSTRAINT platform_accounts_email_key UNIQUE (email);


--
-- Name: platform_accounts platform_accounts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_accounts
    ADD CONSTRAINT platform_accounts_pkey PRIMARY KEY (principal_id);


--
-- Name: platform_checkouts platform_checkouts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_checkouts
    ADD CONSTRAINT platform_checkouts_pkey PRIMARY KEY (id);


--
-- Name: platform_checkouts platform_checkouts_tenant_id_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_checkouts
    ADD CONSTRAINT platform_checkouts_tenant_id_idempotency_key_key UNIQUE (tenant_id, idempotency_key);


--
-- Name: platform_children platform_children_learner_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_learner_id_key UNIQUE (learner_id);


--
-- Name: platform_children platform_children_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_pkey PRIMARY KEY (id);


--
-- Name: platform_children platform_children_principal_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_principal_id_key UNIQUE (principal_id);


--
-- Name: platform_children platform_children_student_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_student_id_key UNIQUE (student_id);


--
-- Name: platform_classes platform_classes_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_classes
    ADD CONSTRAINT platform_classes_pkey PRIMARY KEY (id);


--
-- Name: platform_classes platform_classes_school_id_name_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_classes
    ADD CONSTRAINT platform_classes_school_id_name_key UNIQUE (school_id, name);


--
-- Name: platform_external_identities platform_external_identities_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_external_identities
    ADD CONSTRAINT platform_external_identities_pkey PRIMARY KEY (identity_id);


--
-- Name: platform_external_identities platform_external_identities_provider_principal_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_external_identities
    ADD CONSTRAINT platform_external_identities_provider_principal_id_key UNIQUE (provider, principal_id);


--
-- Name: platform_external_identities platform_external_identities_provider_subject_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_external_identities
    ADD CONSTRAINT platform_external_identities_provider_subject_key UNIQUE (provider, subject);


--
-- Name: platform_join_requests platform_join_requests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_join_requests
    ADD CONSTRAINT platform_join_requests_pkey PRIMARY KEY (id);


--
-- Name: platform_learning_answers platform_learning_answers_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_answers
    ADD CONSTRAINT platform_learning_answers_pkey PRIMARY KEY (session_id, item_id, idempotency_key);


--
-- Name: platform_learning_capabilities platform_learning_capabilities_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_capabilities
    ADD CONSTRAINT platform_learning_capabilities_pkey PRIMARY KEY (code_hash);


--
-- Name: platform_learning_drafts platform_learning_drafts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_drafts
    ADD CONSTRAINT platform_learning_drafts_pkey PRIMARY KEY (session_id, item_id);


--
-- Name: platform_learning_events platform_learning_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_events
    ADD CONSTRAINT platform_learning_events_pkey PRIMARY KEY (id);


--
-- Name: platform_learning_events platform_learning_events_session_id_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_events
    ADD CONSTRAINT platform_learning_events_session_id_idempotency_key_key UNIQUE (session_id, idempotency_key);


--
-- Name: platform_learning_sessions platform_learning_sessions_child_id_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_child_id_idempotency_key_key UNIQUE (child_id, idempotency_key);


--
-- Name: platform_learning_sessions platform_learning_sessions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_pkey PRIMARY KEY (id);


--
-- Name: platform_learning_sessions platform_learning_sessions_test_id_child_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_test_id_child_id_key UNIQUE (test_id, child_id);


--
-- Name: platform_license_requests platform_license_requests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_license_requests
    ADD CONSTRAINT platform_license_requests_pkey PRIMARY KEY (id);


--
-- Name: platform_login_intent platform_login_intent_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_login_intent
    ADD CONSTRAINT platform_login_intent_pkey PRIMARY KEY (intent_id);


--
-- Name: platform_notifications platform_notifications_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_pkey PRIMARY KEY (id);


--
-- Name: platform_notifications platform_notifications_recipient_principal_id_tenant_id_kin_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_recipient_principal_id_tenant_id_kin_key UNIQUE (recipient_principal_id, tenant_id, kind, reference_id);


--
-- Name: platform_password_recovery_intent platform_password_recovery_intent_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_password_recovery_intent
    ADD CONSTRAINT platform_password_recovery_intent_pkey PRIMARY KEY (intent_id);


--
-- Name: platform_placements platform_placements_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_placements
    ADD CONSTRAINT platform_placements_pkey PRIMARY KEY (child_id, class_id);


--
-- Name: platform_push_outbox platform_push_outbox_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_outbox
    ADD CONSTRAINT platform_push_outbox_pkey PRIMARY KEY (notification_id);


--
-- Name: platform_push_preferences platform_push_preferences_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_preferences
    ADD CONSTRAINT platform_push_preferences_pkey PRIMARY KEY (principal_id);


--
-- Name: platform_push_subscriptions platform_push_subscriptions_endpoint_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_subscriptions
    ADD CONSTRAINT platform_push_subscriptions_endpoint_key UNIQUE (endpoint);


--
-- Name: platform_push_subscriptions platform_push_subscriptions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_subscriptions
    ADD CONSTRAINT platform_push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: platform_registration_intent platform_registration_intent_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_registration_intent
    ADD CONSTRAINT platform_registration_intent_pkey PRIMARY KEY (intent_id);


--
-- Name: platform_schools platform_schools_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_schools
    ADD CONSTRAINT platform_schools_pkey PRIMARY KEY (id);


--
-- Name: platform_schools platform_schools_tenant_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_schools
    ADD CONSTRAINT platform_schools_tenant_id_key UNIQUE (tenant_id);


--
-- Name: platform_sessions platform_sessions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_sessions
    ADD CONSTRAINT platform_sessions_pkey PRIMARY KEY (token_hash);


--
-- Name: platform_staff_requests platform_staff_requests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_staff_requests
    ADD CONSTRAINT platform_staff_requests_pkey PRIMARY KEY (id);


--
-- Name: platform_student_access_intent platform_student_access_intent_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_pkey PRIMARY KEY (intent_id);


--
-- Name: platform_student_phone_enrollment_intent platform_student_phone_enrollment_intent_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_phone_enrollment_intent
    ADD CONSTRAINT platform_student_phone_enrollment_intent_pkey PRIMARY KEY (intent_id);


--
-- Name: platform_student_profile_link platform_student_profile_link_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_profile_link
    ADD CONSTRAINT platform_student_profile_link_pkey PRIMARY KEY (link_id);


--
-- Name: platform_student_self_profile platform_student_self_profile_engine_student_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_engine_student_id_key UNIQUE (engine_student_id);


--
-- Name: platform_student_self_profile platform_student_self_profile_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_pkey PRIMARY KEY (profile_id);


--
-- Name: platform_student_self_profile platform_student_self_profile_profile_id_engine_student_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_profile_id_engine_student_id_key UNIQUE (profile_id, engine_student_id);


--
-- Name: platform_student_self_profile platform_student_self_profile_student_principal_id_student__key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_student_principal_id_student__key UNIQUE (student_principal_id, student_tenant_id);


--
-- Name: platform_teacher_classes platform_teacher_classes_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_teacher_classes
    ADD CONSTRAINT platform_teacher_classes_pkey PRIMARY KEY (principal_id, class_id);


--
-- Name: platform_tests platform_tests_created_by_idempotency_key_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_tests
    ADD CONSTRAINT platform_tests_created_by_idempotency_key_key UNIQUE (created_by, idempotency_key);


--
-- Name: platform_tests platform_tests_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_tests
    ADD CONSTRAINT platform_tests_pkey PRIMARY KEY (id);


--
-- Name: platform_trusted_device platform_trusted_device_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_trusted_device
    ADD CONSTRAINT platform_trusted_device_pkey PRIMARY KEY (trusted_device_id);


--
-- Name: platform_trusted_device platform_trusted_device_token_digest_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_trusted_device
    ADD CONSTRAINT platform_trusted_device_token_digest_key UNIQUE (token_digest);


--
-- Name: profile_level_history profile_level_history_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_level_history
    ADD CONSTRAINT profile_level_history_pkey PRIMARY KEY (id);


--
-- Name: profile_level_history profile_level_history_profile_id_effective_from_decision_ki_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_level_history
    ADD CONSTRAINT profile_level_history_profile_id_effective_from_decision_ki_key UNIQUE (profile_id, effective_from, decision_kind);


--
-- Name: profile_pauses profile_pauses_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_pauses
    ADD CONSTRAINT profile_pauses_pkey PRIMARY KEY (id);


--
-- Name: profile_schedules profile_schedules_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_schedules
    ADD CONSTRAINT profile_schedules_pkey PRIMARY KEY (id);


--
-- Name: restore_drills restore_drills_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.restore_drills
    ADD CONSTRAINT restore_drills_pkey PRIMARY KEY (id);


--
-- Name: retake_authorizations retake_authorizations_pack_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.retake_authorizations
    ADD CONSTRAINT retake_authorizations_pack_id_key UNIQUE (pack_id);


--
-- Name: retake_authorizations retake_authorizations_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.retake_authorizations
    ADD CONSTRAINT retake_authorizations_pkey PRIMARY KEY (id);


--
-- Name: retention_runs retention_runs_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.retention_runs
    ADD CONSTRAINT retention_runs_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: skill_event_exclusions skill_event_exclusions_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_event_exclusions
    ADD CONSTRAINT skill_event_exclusions_pkey PRIMARY KEY (id);


--
-- Name: skill_event_exclusions skill_event_exclusions_skill_event_id_reason_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_event_exclusions
    ADD CONSTRAINT skill_event_exclusions_skill_event_id_reason_key UNIQUE (skill_event_id, reason);


--
-- Name: skill_events skill_events_attempt_answer_id_skill_id_score_revision_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_attempt_answer_id_skill_id_score_revision_id_key UNIQUE (attempt_answer_id, skill_id, score_revision_id);


--
-- Name: skill_events skill_events_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_pkey PRIMARY KEY (id);


--
-- Name: skill_prerequisites skill_prerequisites_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_prerequisites
    ADD CONSTRAINT skill_prerequisites_pkey PRIMARY KEY (skill_id, prerequisite_skill_id);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: skills skills_topic_id_code_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skills
    ADD CONSTRAINT skills_topic_id_code_key UNIQUE (topic_id, code);


--
-- Name: slo_daily_aggregates slo_daily_aggregates_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.slo_daily_aggregates
    ADD CONSTRAINT slo_daily_aggregates_pkey PRIMARY KEY (local_date, operation_kind, policy_version);


--
-- Name: telegram_delivery_attempts telegram_delivery_attempts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_delivery_attempts
    ADD CONSTRAINT telegram_delivery_attempts_pkey PRIMARY KEY (id);


--
-- Name: telegram_update_receipts telegram_update_receipts_command_id_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_update_receipts
    ADD CONSTRAINT telegram_update_receipts_command_id_key UNIQUE (command_id);


--
-- Name: telegram_update_receipts telegram_update_receipts_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_update_receipts
    ADD CONSTRAINT telegram_update_receipts_pkey PRIMARY KEY (telegram_update_id);


--
-- Name: topics topics_curriculum_version_id_code_key; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.topics
    ADD CONSTRAINT topics_curriculum_version_id_code_key UNIQUE (curriculum_version_id, code);


--
-- Name: topics topics_id_language_uq; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.topics
    ADD CONSTRAINT topics_id_language_uq UNIQUE (id, language_code);


--
-- Name: topics topics_pkey; Type: CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: answer_widget answer_widget_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.answer_widget
    ADD CONSTRAINT answer_widget_pkey PRIMARY KEY (code);


--
-- Name: billing_order_child billing_order_child_order_id_tenant_id_child_profile_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order_child
    ADD CONSTRAINT billing_order_child_order_id_tenant_id_child_profile_id_key UNIQUE (order_id, tenant_id, child_profile_id);


--
-- Name: billing_order_child billing_order_child_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order_child
    ADD CONSTRAINT billing_order_child_pkey PRIMARY KEY (order_id, child_profile_id);


--
-- Name: billing_order billing_order_order_id_tenant_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order
    ADD CONSTRAINT billing_order_order_id_tenant_id_key UNIQUE (order_id, tenant_id);


--
-- Name: billing_order billing_order_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order
    ADD CONSTRAINT billing_order_pkey PRIMARY KEY (order_id);


--
-- Name: billing_order billing_order_tenant_id_actor_principal_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order
    ADD CONSTRAINT billing_order_tenant_id_actor_principal_id_idempotency_key_key UNIQUE (tenant_id, actor_principal_id, idempotency_key);


--
-- Name: cas_evaluation_request cas_evaluation_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_pkey PRIMARY KEY (request_id);


--
-- Name: cas_evaluation_status cas_evaluation_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_status
    ADD CONSTRAINT cas_evaluation_status_pkey PRIMARY KEY (code);


--
-- Name: cas_operation_type cas_operation_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_operation_type
    ADD CONSTRAINT cas_operation_type_pkey PRIMARY KEY (code);


--
-- Name: cas_submission cas_submission_item_student_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_submission
    ADD CONSTRAINT cas_submission_item_student_idempotency_key_key UNIQUE (item_id, student_id, idempotency_key);


--
-- Name: cas_submission cas_submission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_submission
    ADD CONSTRAINT cas_submission_pkey PRIMARY KEY (submission_id);


--
-- Name: child_entitlement_period child_entitlement_period_order_id_child_profile_id_period_s_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.child_entitlement_period
    ADD CONSTRAINT child_entitlement_period_order_id_child_profile_id_period_s_key UNIQUE (order_id, child_profile_id, period_starts_at);


--
-- Name: child_entitlement_period child_entitlement_period_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.child_entitlement_period
    ADD CONSTRAINT child_entitlement_period_pkey PRIMARY KEY (entitlement_period_id);


--
-- Name: domain domain_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain
    ADD CONSTRAINT domain_pkey PRIMARY KEY (code);


--
-- Name: equivalence_policy equivalence_policy_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equivalence_policy
    ADD CONSTRAINT equivalence_policy_pkey PRIMARY KEY (code);


--
-- Name: event_log event_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_log
    ADD CONSTRAINT event_log_pkey PRIMARY KEY (event_id);


--
-- Name: event_type event_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_type
    ADD CONSTRAINT event_type_pkey PRIMARY KEY (code);


--
-- Name: generation_mode generation_mode_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_mode
    ADD CONSTRAINT generation_mode_pkey PRIMARY KEY (code);


--
-- Name: generation_request generation_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_request
    ADD CONSTRAINT generation_request_pkey PRIMARY KEY (request_id);


--
-- Name: generation_request generation_request_student_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_request
    ADD CONSTRAINT generation_request_student_idempotency_key_key UNIQUE (student_id, idempotency_key);


--
-- Name: grade_band grade_band_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_band
    ADD CONSTRAINT grade_band_pkey PRIMARY KEY (code);


--
-- Name: locale locale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locale
    ADD CONSTRAINT locale_pkey PRIMARY KEY (code);


--
-- Name: mastery_topic mastery_topic_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastery_topic
    ADD CONSTRAINT mastery_topic_pkey PRIMARY KEY (student_id, domain, tier);


--
-- Name: payment_attempt payment_attempt_order_id_attempt_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempt
    ADD CONSTRAINT payment_attempt_order_id_attempt_number_key UNIQUE (order_id, attempt_number);


--
-- Name: payment_attempt payment_attempt_order_id_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempt
    ADD CONSTRAINT payment_attempt_order_id_idempotency_key_key UNIQUE (order_id, idempotency_key);


--
-- Name: payment_attempt payment_attempt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempt
    ADD CONSTRAINT payment_attempt_pkey PRIMARY KEY (payment_attempt_id);


--
-- Name: reason_code reason_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reason_code
    ADD CONSTRAINT reason_code_pkey PRIMARY KEY (code);


--
-- Name: render_target render_target_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.render_target
    ADD CONSTRAINT render_target_pkey PRIMARY KEY (code);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (user_id);


--
-- Name: submission submission_item_student_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_item_student_idempotency_key_key UNIQUE (item_id, student_id, idempotency_key);


--
-- Name: submission submission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_pkey PRIMARY KEY (submission_id);


--
-- Name: task_instance task_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_pkey PRIMARY KEY (item_id);


--
-- Name: task_set task_set_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_set
    ADD CONSTRAINT task_set_pkey PRIMARY KEY (task_set_id);


--
-- Name: task_set task_set_student_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_set
    ADD CONSTRAINT task_set_student_idempotency_key_key UNIQUE (student_id, idempotency_key);


--
-- Name: task_type task_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_pkey PRIMARY KEY (type_id);


--
-- Name: task_type_status task_type_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type_status
    ADD CONSTRAINT task_type_status_pkey PRIMARY KEY (code);


--
-- Name: task_type_template task_type_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type_template
    ADD CONSTRAINT task_type_template_pkey PRIMARY KEY (type_id, locale, render_target, spec_version);


--
-- Name: tier_code tier_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tier_code
    ADD CONSTRAINT tier_code_pkey PRIMARY KEY (code);


--
-- Name: user_type user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (code);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: validation_method validation_method_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.validation_method
    ADD CONSTRAINT validation_method_pkey PRIMARY KEY (code);


--
-- Name: verdict verdict_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verdict
    ADD CONSTRAINT verdict_pkey PRIMARY KEY (code);


--
-- Name: verified_provider_event verified_provider_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verified_provider_event
    ADD CONSTRAINT verified_provider_event_pkey PRIMARY KEY (verified_provider_event_id);


--
-- Name: verified_provider_event verified_provider_event_provider_code_provider_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verified_provider_event
    ADD CONSTRAINT verified_provider_event_provider_code_provider_event_id_key UNIQUE (provider_code, provider_event_id);


--
-- Name: access_consents_active_purpose_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX access_consents_active_purpose_uq ON mathprep.access_consents USING btree (tenant_id, guardian_relationship_id, purpose) WHERE (state = 'granted'::text);


--
-- Name: access_invitations_recipient_identity_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX access_invitations_recipient_identity_idx ON mathprep.access_invitations USING btree (recipient_provider, recipient_identity_ref) WHERE (recipient_provider IS NOT NULL);


--
-- Name: access_memberships_principal_tenant_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX access_memberships_principal_tenant_idx ON mathprep.access_memberships USING btree (principal_id, tenant_id) WHERE (status = 'active'::text);


--
-- Name: active_token_per_pack_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX active_token_per_pack_uq ON mathprep.pack_access_tokens USING btree (pack_id) WHERE (state = ANY (ARRAY['issued'::text, 'active'::text]));


--
-- Name: adaptation_rule_one_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX adaptation_rule_one_active_uq ON mathprep.adaptation_rule_versions USING btree (status) WHERE (status = 'active'::text);


--
-- Name: assistance_item_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX assistance_item_active_uq ON mathprep.assistance_marks USING btree (pack_id, pack_item_id) WHERE ((pack_item_id IS NOT NULL) AND (state = 'active'::text));


--
-- Name: assistance_pack_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX assistance_pack_active_uq ON mathprep.assistance_marks USING btree (pack_id) WHERE ((pack_item_id IS NULL) AND (state = 'active'::text));


--
-- Name: attempts_one_initial_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX attempts_one_initial_uq ON mathprep.attempts USING btree (pack_id) WHERE (attempt_kind = 'initial'::text);


--
-- Name: attempts_one_retake_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX attempts_one_retake_uq ON mathprep.attempts USING btree (pack_id) WHERE (attempt_kind = 'retake'::text);


--
-- Name: content_readiness_runs_profile_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX content_readiness_runs_profile_idx ON mathprep.content_readiness_runs USING btree (profile_id, completed_at DESC);


--
-- Name: content_reports_open_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX content_reports_open_uq ON mathprep.content_reports USING btree (parent_id, pack_item_id, defect_kind) WHERE (state = 'open'::text);


--
-- Name: curriculum_one_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX curriculum_one_active_uq ON mathprep.curriculum_versions USING btree (country_code, subject_code, language_code, academic_year) WHERE (status = 'active'::text);


--
-- Name: difficulty_override_consumed_pack_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX difficulty_override_consumed_pack_uq ON mathprep.difficulty_override_events USING btree (override_id, pack_id) WHERE (event_type = 'consumed'::text);


--
-- Name: difficulty_override_events_history_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX difficulty_override_events_history_idx ON mathprep.difficulty_override_events USING btree (override_id, occurred_at DESC);


--
-- Name: difficulty_overrides_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX difficulty_overrides_active_uq ON mathprep.difficulty_overrides USING btree (profile_id) WHERE (status = 'active'::text);


--
-- Name: item_version_one_primary_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX item_version_one_primary_uq ON mathprep.item_version_skills USING btree (item_version_id) WHERE is_primary;


--
-- Name: item_versions_candidates_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX item_versions_candidates_idx ON mathprep.item_versions USING btree (status, language_code, grade_min, grade_max, difficulty_level) WHERE (status = 'approved'::text);


--
-- Name: jobs_due_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX jobs_due_idx ON mathprep.jobs USING btree (status, run_after, id) WHERE (status = ANY (ARRAY['queued'::text, 'retry_wait'::text]));


--
-- Name: jobs_lease_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX jobs_lease_idx ON mathprep.jobs USING btree (lease_expires_at) WHERE (status = 'leased'::text);


--
-- Name: learner_profiles_current_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX learner_profiles_current_uq ON mathprep.learner_profiles USING btree (learner_id) WHERE (status = ANY (ARRAY['draft'::text, 'active'::text, 'paused'::text]));


--
-- Name: learner_profiles_tenant_id_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX learner_profiles_tenant_id_idx ON mathprep.learner_profiles USING btree (tenant_id, id);


--
-- Name: learners_parent_pseudonym_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX learners_parent_pseudonym_uq ON mathprep.learners USING btree (parent_id, lower((pseudonym)::text));


--
-- Name: learners_tenant_id_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX learners_tenant_id_idx ON mathprep.learners USING btree (tenant_id, id);


--
-- Name: pack_access_extension_command_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX pack_access_extension_command_uq ON mathprep.pack_access_tokens USING btree (extension_command_id) WHERE (extension_command_id IS NOT NULL);


--
-- Name: pack_item_one_primary_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX pack_item_one_primary_uq ON mathprep.pack_item_skills USING btree (pack_item_id) WHERE (role = 'primary'::text);


--
-- Name: packs_one_planned_per_day_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX packs_one_planned_per_day_uq ON mathprep.packs USING btree (profile_id, local_date) WHERE (pack_type = 'planned'::text);


--
-- Name: packs_profile_date_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX packs_profile_date_idx ON mathprep.packs USING btree (profile_id, local_date DESC);


--
-- Name: packs_tenant_id_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX packs_tenant_id_idx ON mathprep.packs USING btree (tenant_id, id);


--
-- Name: parent_consents_active_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX parent_consents_active_uq ON mathprep.parent_consents USING btree (parent_id, consent_kind) WHERE (withdrawn_at IS NULL);


--
-- Name: phone_identity_one_current_per_principal_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX phone_identity_one_current_per_principal_uq ON mathprep.phone_identity USING btree (principal_id) WHERE (status = ANY (ARRAY['pending'::text, 'verified'::text]));


--
-- Name: phone_identity_principal_history_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX phone_identity_principal_history_idx ON mathprep.phone_identity USING btree (principal_id, created_at DESC);


--
-- Name: phone_identity_verified_phone_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX phone_identity_verified_phone_uq ON mathprep.phone_identity USING btree (phone_e164) WHERE (status = 'verified'::text);


--
-- Name: platform_children_tenant_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_children_tenant_idx ON mathprep.platform_children USING btree (tenant_id, id);


--
-- Name: platform_join_class_status; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_join_class_status ON mathprep.platform_join_requests USING btree (class_id, status);


--
-- Name: platform_learning_child_created_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_learning_child_created_idx ON mathprep.platform_learning_sessions USING btree (child_id, created_at DESC);


--
-- Name: platform_learning_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_learning_expiry_idx ON mathprep.platform_learning_sessions USING btree (deadline) WHERE (status = ANY (ARRAY['active'::text, 'generating'::text, 'finalizing'::text]));


--
-- Name: platform_learning_sessions_profile_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_learning_sessions_profile_idx ON mathprep.platform_learning_sessions USING btree (self_profile_id, created_at DESC) WHERE (self_profile_id IS NOT NULL);


--
-- Name: platform_learning_sessions_self_idempotency_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_learning_sessions_self_idempotency_idx ON mathprep.platform_learning_sessions USING btree (self_profile_id, idempotency_key) WHERE (self_profile_id IS NOT NULL);


--
-- Name: platform_license_school_status; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_license_school_status ON mathprep.platform_license_requests USING btree (school_id, status);


--
-- Name: platform_login_intent_pending_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_login_intent_pending_expiry_idx ON mathprep.platform_login_intent USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_login_intent_pending_principal_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_login_intent_pending_principal_idx ON mathprep.platform_login_intent USING btree (principal_id, expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_login_intent_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_login_intent_retention_idx ON mathprep.platform_login_intent USING btree (expires_at);


--
-- Name: platform_notifications_assessment_ready_session_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_notifications_assessment_ready_session_uq ON mathprep.platform_notifications USING btree (recipient_principal_id, tenant_id, session_id) WHERE (kind = 'assessment_ready'::text);


--
-- Name: platform_notifications_inbox; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_notifications_inbox ON mathprep.platform_notifications USING btree (recipient_principal_id, tenant_id, created_at DESC);


--
-- Name: platform_notifications_push_outbox_identity_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_notifications_push_outbox_identity_uq ON mathprep.platform_notifications USING btree (id, recipient_principal_id, kind);


--
-- Name: platform_one_active_placement; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_one_active_placement ON mathprep.platform_placements USING btree (child_id) WHERE (status = 'active'::text);


--
-- Name: platform_password_recovery_one_pending_principal_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_password_recovery_one_pending_principal_idx ON mathprep.platform_password_recovery_intent USING btree (principal_id) WHERE (status = 'pending'::text);


--
-- Name: platform_password_recovery_pending_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_password_recovery_pending_expiry_idx ON mathprep.platform_password_recovery_intent USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_password_recovery_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_password_recovery_retention_idx ON mathprep.platform_password_recovery_intent USING btree (expires_at, completed_at);


--
-- Name: platform_pending_join; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_pending_join ON mathprep.platform_join_requests USING btree (child_id, class_id) WHERE (status = 'pending'::text);


--
-- Name: platform_placement_class_status; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_placement_class_status ON mathprep.platform_placements USING btree (class_id, status);


--
-- Name: platform_push_outbox_expired_lease_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_push_outbox_expired_lease_idx ON mathprep.platform_push_outbox USING btree (lease_expires_at, created_at) WHERE (status = 'in_progress'::text);


--
-- Name: platform_push_outbox_pending_claim_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_push_outbox_pending_claim_idx ON mathprep.platform_push_outbox USING btree (next_attempt_at, created_at) WHERE (status = 'pending'::text);


--
-- Name: platform_push_subscriptions_principal_active_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_push_subscriptions_principal_active_idx ON mathprep.platform_push_subscriptions USING btree (principal_id, created_at) WHERE (revoked_at IS NULL);


--
-- Name: platform_registration_intent_pending_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_registration_intent_pending_expiry_idx ON mathprep.platform_registration_intent USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_registration_intent_pending_phone_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_registration_intent_pending_phone_idx ON mathprep.platform_registration_intent USING btree (phone_e164, expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_registration_intent_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_registration_intent_retention_idx ON mathprep.platform_registration_intent USING btree (expires_at, finalized_at);


--
-- Name: platform_sessions_principal_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_sessions_principal_idx ON mathprep.platform_sessions USING btree (principal_id);


--
-- Name: platform_staff_pending; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_staff_pending ON mathprep.platform_staff_requests USING btree (principal_id, school_id, requested_role) WHERE (status = 'pending'::text);


--
-- Name: platform_student_access_one_pending_child_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_student_access_one_pending_child_idx ON mathprep.platform_student_access_intent USING btree (child_id) WHERE (status = 'pending'::text);


--
-- Name: platform_student_access_pending_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_student_access_pending_expiry_idx ON mathprep.platform_student_access_intent USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_student_access_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_student_access_retention_idx ON mathprep.platform_student_access_intent USING btree (expires_at, finalized_at);


--
-- Name: platform_student_phone_enrollment_one_pending_principal_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_student_phone_enrollment_one_pending_principal_idx ON mathprep.platform_student_phone_enrollment_intent USING btree (principal_id) WHERE (status = 'pending'::text);


--
-- Name: platform_student_phone_enrollment_pending_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_student_phone_enrollment_pending_expiry_idx ON mathprep.platform_student_phone_enrollment_intent USING btree (expires_at) WHERE (status = 'pending'::text);


--
-- Name: platform_student_phone_enrollment_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_student_phone_enrollment_retention_idx ON mathprep.platform_student_phone_enrollment_intent USING btree (expires_at, completed_at);


--
-- Name: platform_student_profile_link_child_open_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_student_profile_link_child_open_idx ON mathprep.platform_student_profile_link USING btree (child_id) WHERE ((child_id IS NOT NULL) AND (status = ANY (ARRAY['pending_student'::text, 'active'::text])));


--
-- Name: platform_student_profile_link_code_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_student_profile_link_code_idx ON mathprep.platform_student_profile_link USING btree (pairing_code_digest) WHERE (status = 'pending_family'::text);


--
-- Name: platform_student_profile_link_expiry_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_student_profile_link_expiry_idx ON mathprep.platform_student_profile_link USING btree (expires_at) WHERE (status = ANY (ARRAY['pending_family'::text, 'pending_student'::text]));


--
-- Name: platform_student_profile_link_student_open_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX platform_student_profile_link_student_open_idx ON mathprep.platform_student_profile_link USING btree (student_principal_id) WHERE (status = ANY (ARRAY['pending_family'::text, 'pending_student'::text, 'active'::text]));


--
-- Name: platform_tests_class_homework_due_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_tests_class_homework_due_idx ON mathprep.platform_tests USING btree (class_id, due_at) WHERE (kind = 'homework'::text);


--
-- Name: platform_trusted_device_principal_active_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_trusted_device_principal_active_idx ON mathprep.platform_trusted_device USING btree (principal_id, expires_at) WHERE (revoked_at IS NULL);


--
-- Name: platform_trusted_device_retention_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX platform_trusted_device_retention_idx ON mathprep.platform_trusted_device USING btree (expires_at, revoked_at);


--
-- Name: profile_schedules_current_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX profile_schedules_current_uq ON mathprep.profile_schedules USING btree (profile_id) WHERE (effective_to IS NULL);


--
-- Name: projection_review_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX projection_review_idx ON mathprep.learner_skill_projection USING btree (profile_id, status, next_review_on, skill_id);


--
-- Name: restore_drills_evidence_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX restore_drills_evidence_idx ON mathprep.restore_drills USING btree (backup_run_id, finished_at DESC);


--
-- Name: retention_runs_daily_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX retention_runs_daily_uq ON mathprep.retention_runs USING btree (policy_version, data_class, cutoff_at);


--
-- Name: skill_events_projection_idx; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE INDEX skill_events_projection_idx ON mathprep.skill_events USING btree (profile_id, skill_id, occurred_at DESC);


--
-- Name: telegram_initial_attempt_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX telegram_initial_attempt_uq ON mathprep.telegram_delivery_attempts USING btree (pack_id, initial_retry_no) WHERE (delivery_kind = 'initial_retry'::text);


--
-- Name: telegram_manual_attempt_uq; Type: INDEX; Schema: mathprep; Owner: -
--

CREATE UNIQUE INDEX telegram_manual_attempt_uq ON mathprep.telegram_delivery_attempts USING btree (pack_id, parent_command_id) WHERE (delivery_kind = 'manual_resend'::text);


--
-- Name: billing_order_actor_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX billing_order_actor_recent_idx ON public.billing_order USING btree (tenant_id, actor_principal_id, created_at DESC);


--
-- Name: cas_evaluation_request_claim_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cas_evaluation_request_claim_idx ON public.cas_evaluation_request USING btree (status, lease_expires_at, created_at);


--
-- Name: cas_evaluation_request_session_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cas_evaluation_request_session_created_at_idx ON public.cas_evaluation_request USING btree (session_id, created_at);


--
-- Name: child_entitlement_period_child_window_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX child_entitlement_period_child_window_idx ON public.child_entitlement_period USING btree (tenant_id, child_profile_id, period_starts_at, period_ends_at);


--
-- Name: payment_attempt_halyk_invoice_suffix6_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_attempt_halyk_invoice_suffix6_uq ON public.payment_attempt USING btree ("right"(provider_invoice_id, 6)) WHERE ((provider_code = 'halyk_epay'::text) AND (provider_invoice_id IS NOT NULL));


--
-- Name: payment_attempt_order_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX payment_attempt_order_recent_idx ON public.payment_attempt USING btree (order_id, created_at DESC);


--
-- Name: payment_attempt_provider_invoice_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_attempt_provider_invoice_uq ON public.payment_attempt USING btree (provider_code, provider_invoice_id) WHERE (provider_invoice_id IS NOT NULL);


--
-- Name: payment_attempt_provider_payment_uq; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX payment_attempt_provider_payment_uq ON public.payment_attempt USING btree (provider_code, provider_payment_id) WHERE (provider_payment_id IS NOT NULL);


--
-- Name: task_type_template_lookup_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX task_type_template_lookup_idx ON public.task_type_template USING btree (type_id, locale, render_target);


--
-- Name: verified_provider_event_attempt_recent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX verified_provider_event_attempt_recent_idx ON public.verified_provider_event USING btree (payment_attempt_id, received_at DESC) WHERE (payment_attempt_id IS NOT NULL);


--
-- Name: access_audit_events access_audit_events_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER access_audit_events_append_only BEFORE DELETE OR UPDATE ON mathprep.access_audit_events FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: access_consents access_consents_tenant_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER access_consents_tenant_guard BEFORE INSERT OR UPDATE OF tenant_id, guardian_relationship_id, actor_principal_id ON mathprep.access_consents FOR EACH ROW EXECUTE FUNCTION mathprep.access_consent_tenant_guard();


--
-- Name: access_consents access_null_consent_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER access_null_consent_guard BEFORE INSERT OR UPDATE ON mathprep.access_consents FOR EACH ROW EXECUTE FUNCTION mathprep.access_null_consent_guard();


--
-- Name: access_recovery_cases access_recovery_cases_tenant_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER access_recovery_cases_tenant_guard BEFORE INSERT OR UPDATE OF tenant_id, principal_id ON mathprep.access_recovery_cases FOR EACH ROW EXECUTE FUNCTION mathprep.access_recovery_tenant_guard();


--
-- Name: attempt_answers attempt_answers_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER attempt_answers_append_only BEFORE DELETE OR UPDATE ON mathprep.attempt_answers FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: content_decision_events content_decision_events_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER content_decision_events_append_only BEFORE DELETE OR UPDATE ON mathprep.content_decision_events FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: difficulty_override_events difficulty_override_events_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER difficulty_override_events_append_only BEFORE DELETE OR UPDATE ON mathprep.difficulty_override_events FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: answer_evaluation_revisions evaluation_revisions_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER evaluation_revisions_append_only BEFORE DELETE OR UPDATE ON mathprep.answer_evaluation_revisions FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: access_guardian_relationships guardian_relationship_tenant_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER guardian_relationship_tenant_guard BEFORE INSERT OR UPDATE OF tenant_id, learner_id ON mathprep.access_guardian_relationships FOR EACH ROW EXECUTE FUNCTION mathprep.guardian_relationship_tenant_guard();


--
-- Name: item_version_skills item_version_skills_language_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE CONSTRAINT TRIGGER item_version_skills_language_guard AFTER INSERT OR UPDATE ON mathprep.item_version_skills DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION mathprep.validate_item_skill_language();


--
-- Name: learner_profiles learner_profiles_assign_tenant; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER learner_profiles_assign_tenant BEFORE INSERT OR UPDATE OF parent_id, tenant_id ON mathprep.learner_profiles FOR EACH ROW EXECUTE FUNCTION mathprep.assign_legacy_tenant();


--
-- Name: learners learners_assign_tenant; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER learners_assign_tenant BEFORE INSERT OR UPDATE OF parent_id, tenant_id ON mathprep.learners FOR EACH ROW EXECUTE FUNCTION mathprep.assign_legacy_tenant();


--
-- Name: learners learners_limit_two; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER learners_limit_two BEFORE INSERT OR UPDATE OF parent_id, status ON mathprep.learners FOR EACH ROW EXECUTE FUNCTION mathprep.limit_active_learners();


--
-- Name: pack_items pack_items_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER pack_items_append_only BEFORE DELETE OR UPDATE ON mathprep.pack_items FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: pack_items pack_items_language_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER pack_items_language_guard BEFORE INSERT OR UPDATE OF pack_id, source_item_version_id ON mathprep.pack_items FOR EACH ROW EXECUTE FUNCTION mathprep.validate_pack_item_language();


--
-- Name: packs packs_assign_tenant; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER packs_assign_tenant BEFORE INSERT OR UPDATE OF parent_id, tenant_id ON mathprep.packs FOR EACH ROW EXECUTE FUNCTION mathprep.assign_legacy_tenant();


--
-- Name: packs packs_language_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER packs_language_guard BEFORE INSERT OR UPDATE OF profile_id, curriculum_version_id ON mathprep.packs FOR EACH ROW EXECUTE FUNCTION mathprep.validate_pack_language();


--
-- Name: platform_children platform_child_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_child_guard BEFORE INSERT OR UPDATE ON mathprep.platform_children FOR EACH ROW EXECUTE FUNCTION mathprep.platform_child_guard();


--
-- Name: platform_license_requests platform_license_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_license_guard BEFORE INSERT OR UPDATE ON mathprep.platform_license_requests FOR EACH ROW EXECUTE FUNCTION mathprep.platform_license_guard();


--
-- Name: platform_student_access_intent platform_student_access_lifecycle_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_access_lifecycle_guard BEFORE UPDATE ON mathprep.platform_student_access_intent FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_access_intent_transition();


--
-- Name: platform_student_access_intent platform_student_access_scope_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_access_scope_guard BEFORE INSERT ON mathprep.platform_student_access_intent FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_access_intent_scope();


--
-- Name: platform_student_phone_enrollment_intent platform_student_phone_enrollment_lifecycle_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_phone_enrollment_lifecycle_guard BEFORE UPDATE ON mathprep.platform_student_phone_enrollment_intent FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_phone_enrollment_transition();


--
-- Name: platform_student_phone_enrollment_intent platform_student_phone_enrollment_scope_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_phone_enrollment_scope_guard BEFORE INSERT ON mathprep.platform_student_phone_enrollment_intent FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_phone_enrollment_scope();


--
-- Name: platform_student_profile_link platform_student_profile_link_lifecycle_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_profile_link_lifecycle_guard BEFORE UPDATE ON mathprep.platform_student_profile_link FOR EACH ROW EXECUTE FUNCTION mathprep.guard_student_profile_link_transition();


--
-- Name: platform_student_profile_link platform_student_profile_link_scope_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_profile_link_scope_guard BEFORE INSERT OR UPDATE ON mathprep.platform_student_profile_link FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_profile_link_scope();


--
-- Name: platform_student_self_profile platform_student_self_profile_owner_guard; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_student_self_profile_owner_guard BEFORE INSERT ON mathprep.platform_student_self_profile FOR EACH ROW EXECUTE FUNCTION mathprep.assert_student_self_profile_owner();


--
-- Name: platform_teacher_classes platform_teacher_class_scope; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER platform_teacher_class_scope BEFORE INSERT OR UPDATE ON mathprep.platform_teacher_classes FOR EACH ROW EXECUTE FUNCTION mathprep.platform_teacher_class_guard();


--
-- Name: retention_runs retention_runs_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER retention_runs_append_only BEFORE DELETE OR UPDATE ON mathprep.retention_runs FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: attempt_score_revisions score_revisions_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER score_revisions_append_only BEFORE DELETE OR UPDATE ON mathprep.attempt_score_revisions FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: skill_events skill_events_append_only; Type: TRIGGER; Schema: mathprep; Owner: -
--

CREATE TRIGGER skill_events_append_only BEFORE DELETE OR UPDATE ON mathprep.skill_events FOR EACH ROW EXECUTE FUNCTION mathprep.reject_mutation();


--
-- Name: mastery_topic mastery_topic_evidence_count_write; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER mastery_topic_evidence_count_write BEFORE INSERT OR UPDATE ON public.mastery_topic FOR EACH ROW EXECUTE FUNCTION public.set_mastery_topic_evidence_count();


--
-- Name: access_audit_events access_audit_events_actor_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_audit_events
    ADD CONSTRAINT access_audit_events_actor_principal_id_fkey FOREIGN KEY (actor_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_audit_events access_audit_events_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_audit_events
    ADD CONSTRAINT access_audit_events_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_consents access_consents_actor_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_consents
    ADD CONSTRAINT access_consents_actor_principal_id_fkey FOREIGN KEY (actor_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_consents access_consents_guardian_relationship_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_consents
    ADD CONSTRAINT access_consents_guardian_relationship_id_fkey FOREIGN KEY (guardian_relationship_id) REFERENCES mathprep.access_guardian_relationships(id) ON DELETE RESTRICT;


--
-- Name: access_consents access_consents_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_consents
    ADD CONSTRAINT access_consents_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_external_identities access_external_identities_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_external_identities
    ADD CONSTRAINT access_external_identities_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_guardian_relationships access_guardian_relationships_guardian_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_guardian_relationships
    ADD CONSTRAINT access_guardian_relationships_guardian_principal_id_fkey FOREIGN KEY (guardian_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_guardian_relationships access_guardian_relationships_learner_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_guardian_relationships
    ADD CONSTRAINT access_guardian_relationships_learner_id_fkey FOREIGN KEY (learner_id) REFERENCES mathprep.learners(id) ON DELETE RESTRICT;


--
-- Name: access_guardian_relationships access_guardian_relationships_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_guardian_relationships
    ADD CONSTRAINT access_guardian_relationships_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_invitations access_invitations_created_by_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_invitations
    ADD CONSTRAINT access_invitations_created_by_principal_id_fkey FOREIGN KEY (created_by_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_invitations access_invitations_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_invitations
    ADD CONSTRAINT access_invitations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_legacy_parent_mappings access_legacy_parent_mappings_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_legacy_parent_mappings
    ADD CONSTRAINT access_legacy_parent_mappings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_memberships access_memberships_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_memberships
    ADD CONSTRAINT access_memberships_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_memberships access_memberships_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_memberships
    ADD CONSTRAINT access_memberships_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: access_recovery_cases access_recovery_cases_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_recovery_cases
    ADD CONSTRAINT access_recovery_cases_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: access_recovery_cases access_recovery_cases_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.access_recovery_cases
    ADD CONSTRAINT access_recovery_cases_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: answer_evaluation_revisions answer_evaluation_revisions_attempt_answer_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.answer_evaluation_revisions
    ADD CONSTRAINT answer_evaluation_revisions_attempt_answer_id_fkey FOREIGN KEY (attempt_answer_id) REFERENCES mathprep.attempt_answers(id) ON DELETE CASCADE;


--
-- Name: answer_evaluation_revisions answer_evaluation_revisions_score_revision_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.answer_evaluation_revisions
    ADD CONSTRAINT answer_evaluation_revisions_score_revision_id_fkey FOREIGN KEY (score_revision_id) REFERENCES mathprep.attempt_score_revisions(id) ON DELETE CASCADE;


--
-- Name: assistance_marks assistance_marks_pack_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.assistance_marks
    ADD CONSTRAINT assistance_marks_pack_id_parent_id_fkey FOREIGN KEY (pack_id, parent_id) REFERENCES mathprep.packs(id, parent_id) ON DELETE CASCADE;


--
-- Name: assistance_marks assistance_marks_pack_item_id_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.assistance_marks
    ADD CONSTRAINT assistance_marks_pack_item_id_pack_id_fkey FOREIGN KEY (pack_item_id, pack_id) REFERENCES mathprep.pack_items(id, pack_id) ON DELETE CASCADE;


--
-- Name: attempt_answers attempt_answers_attempt_id_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_answers
    ADD CONSTRAINT attempt_answers_attempt_id_pack_id_fkey FOREIGN KEY (attempt_id, pack_id) REFERENCES mathprep.attempts(id, pack_id) ON DELETE CASCADE;


--
-- Name: attempt_answers attempt_answers_pack_item_id_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_answers
    ADD CONSTRAINT attempt_answers_pack_item_id_pack_id_fkey FOREIGN KEY (pack_item_id, pack_id) REFERENCES mathprep.pack_items(id, pack_id) ON DELETE CASCADE;


--
-- Name: attempt_score_revisions attempt_score_revisions_attempt_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempt_score_revisions
    ADD CONSTRAINT attempt_score_revisions_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES mathprep.attempts(id) ON DELETE CASCADE;


--
-- Name: attempts attempts_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.attempts
    ADD CONSTRAINT attempts_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: backup_artifact_manifests backup_artifact_manifests_backup_run_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.backup_artifact_manifests
    ADD CONSTRAINT backup_artifact_manifests_backup_run_id_fkey FOREIGN KEY (backup_run_id) REFERENCES mathprep.backup_runs(id) ON DELETE CASCADE;


--
-- Name: content_decision_events content_decision_events_actor_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_decision_events
    ADD CONSTRAINT content_decision_events_actor_parent_id_fkey FOREIGN KEY (actor_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: content_decision_events content_decision_events_content_incident_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_decision_events
    ADD CONSTRAINT content_decision_events_content_incident_id_fkey FOREIGN KEY (content_incident_id) REFERENCES mathprep.content_incidents(id) ON DELETE RESTRICT;


--
-- Name: content_decision_events content_decision_events_content_report_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_decision_events
    ADD CONSTRAINT content_decision_events_content_report_id_fkey FOREIGN KEY (content_report_id) REFERENCES mathprep.content_reports(id) ON DELETE RESTRICT;


--
-- Name: content_decision_events content_decision_events_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_decision_events
    ADD CONSTRAINT content_decision_events_item_version_id_fkey FOREIGN KEY (item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: content_incident_pack_items content_incident_pack_items_incident_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incident_pack_items
    ADD CONSTRAINT content_incident_pack_items_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES mathprep.content_incidents(id) ON DELETE CASCADE;


--
-- Name: content_incident_pack_items content_incident_pack_items_pack_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incident_pack_items
    ADD CONSTRAINT content_incident_pack_items_pack_item_id_fkey FOREIGN KEY (pack_item_id) REFERENCES mathprep.pack_items(id) ON DELETE CASCADE;


--
-- Name: content_incidents content_incidents_confirmed_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incidents
    ADD CONSTRAINT content_incidents_confirmed_by_parent_id_fkey FOREIGN KEY (confirmed_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: content_incidents content_incidents_corrected_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incidents
    ADD CONSTRAINT content_incidents_corrected_item_version_id_fkey FOREIGN KEY (corrected_item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: content_incidents content_incidents_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_incidents
    ADD CONSTRAINT content_incidents_item_version_id_fkey FOREIGN KEY (item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: content_readiness_run_days content_readiness_run_days_run_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_run_days
    ADD CONSTRAINT content_readiness_run_days_run_id_fkey FOREIGN KEY (run_id) REFERENCES mathprep.content_readiness_runs(id) ON DELETE CASCADE;


--
-- Name: content_readiness_runs content_readiness_runs_curriculum_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_runs
    ADD CONSTRAINT content_readiness_runs_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES mathprep.curriculum_versions(id) ON DELETE RESTRICT;


--
-- Name: content_readiness_runs content_readiness_runs_initiated_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_runs
    ADD CONSTRAINT content_readiness_runs_initiated_by_parent_id_fkey FOREIGN KEY (initiated_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: content_readiness_runs content_readiness_runs_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_runs
    ADD CONSTRAINT content_readiness_runs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: content_readiness_runs content_readiness_runs_rule_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_readiness_runs
    ADD CONSTRAINT content_readiness_runs_rule_version_id_fkey FOREIGN KEY (rule_version_id) REFERENCES mathprep.adaptation_rule_versions(id) ON DELETE RESTRICT;


--
-- Name: content_reports content_reports_pack_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_reports
    ADD CONSTRAINT content_reports_pack_id_parent_id_fkey FOREIGN KEY (pack_id, parent_id) REFERENCES mathprep.packs(id, parent_id) ON DELETE CASCADE;


--
-- Name: content_reports content_reports_pack_item_id_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_reports
    ADD CONSTRAINT content_reports_pack_item_id_pack_id_fkey FOREIGN KEY (pack_item_id, pack_id) REFERENCES mathprep.pack_items(id, pack_id) ON DELETE CASCADE;


--
-- Name: content_reports content_reports_resolved_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.content_reports
    ADD CONSTRAINT content_reports_resolved_by_parent_id_fkey FOREIGN KEY (resolved_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: deletion_requests deletion_requests_learner_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.deletion_requests
    ADD CONSTRAINT deletion_requests_learner_id_fkey FOREIGN KEY (learner_id) REFERENCES mathprep.learners(id) ON DELETE SET NULL;


--
-- Name: deletion_requests deletion_requests_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.deletion_requests
    ADD CONSTRAINT deletion_requests_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE SET NULL;


--
-- Name: difficulty_override_events difficulty_override_events_created_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_created_by_parent_id_fkey FOREIGN KEY (created_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: difficulty_override_events difficulty_override_events_override_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_override_id_fkey FOREIGN KEY (override_id) REFERENCES mathprep.difficulty_overrides(id) ON DELETE RESTRICT;


--
-- Name: difficulty_override_events difficulty_override_events_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE RESTRICT;


--
-- Name: difficulty_override_events difficulty_override_events_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE RESTRICT;


--
-- Name: difficulty_override_events difficulty_override_events_replaced_by_override_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_override_events
    ADD CONSTRAINT difficulty_override_events_replaced_by_override_id_fkey FOREIGN KEY (replaced_by_override_id) REFERENCES mathprep.difficulty_overrides(id) ON DELETE RESTRICT;


--
-- Name: difficulty_overrides difficulty_overrides_created_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_overrides
    ADD CONSTRAINT difficulty_overrides_created_by_parent_id_fkey FOREIGN KEY (created_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: difficulty_overrides difficulty_overrides_last_consumed_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_overrides
    ADD CONSTRAINT difficulty_overrides_last_consumed_pack_id_fkey FOREIGN KEY (last_consumed_pack_id) REFERENCES mathprep.packs(id) ON DELETE RESTRICT;


--
-- Name: difficulty_overrides difficulty_overrides_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.difficulty_overrides
    ADD CONSTRAINT difficulty_overrides_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: item_instances item_instances_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_instances
    ADD CONSTRAINT item_instances_item_version_id_fkey FOREIGN KEY (item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: item_version_skills item_version_skills_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_version_skills
    ADD CONSTRAINT item_version_skills_item_version_id_fkey FOREIGN KEY (item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: item_version_skills item_version_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_version_skills
    ADD CONSTRAINT item_version_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: item_versions item_versions_approved_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_versions
    ADD CONSTRAINT item_versions_approved_by_parent_id_fkey FOREIGN KEY (approved_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: item_versions item_versions_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.item_versions
    ADD CONSTRAINT item_versions_item_id_fkey FOREIGN KEY (item_id) REFERENCES mathprep.items(id) ON DELETE RESTRICT;


--
-- Name: job_attempts job_attempts_job_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.job_attempts
    ADD CONSTRAINT job_attempts_job_id_fkey FOREIGN KEY (job_id) REFERENCES mathprep.jobs(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_incident_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.jobs
    ADD CONSTRAINT jobs_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES mathprep.content_incidents(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.jobs
    ADD CONSTRAINT jobs_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.jobs
    ADD CONSTRAINT jobs_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: learner_profiles learner_profiles_active_topic_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_active_topic_id_fkey FOREIGN KEY (active_topic_id) REFERENCES mathprep.topics(id) ON DELETE RESTRICT;


--
-- Name: learner_profiles learner_profiles_curriculum_language_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_curriculum_language_fk FOREIGN KEY (curriculum_version_id, language_code) REFERENCES mathprep.curriculum_versions(id, language_code) ON DELETE RESTRICT;


--
-- Name: learner_profiles learner_profiles_curriculum_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES mathprep.curriculum_versions(id) ON DELETE RESTRICT;


--
-- Name: learner_profiles learner_profiles_learner_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_learner_id_parent_id_fkey FOREIGN KEY (learner_id, parent_id) REFERENCES mathprep.learners(id, parent_id) ON DELETE CASCADE;


--
-- Name: learner_profiles learner_profiles_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE CASCADE;


--
-- Name: learner_profiles learner_profiles_tenant_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_tenant_fk FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: learner_profiles learner_profiles_topic_language_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_profiles
    ADD CONSTRAINT learner_profiles_topic_language_fk FOREIGN KEY (active_topic_id, language_code) REFERENCES mathprep.topics(id, language_code) ON DELETE RESTRICT;


--
-- Name: learner_skill_projection learner_skill_projection_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_skill_projection
    ADD CONSTRAINT learner_skill_projection_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: learner_skill_projection learner_skill_projection_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_skill_projection
    ADD CONSTRAINT learner_skill_projection_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: learner_skill_projection learner_skill_projection_source_rule_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learner_skill_projection
    ADD CONSTRAINT learner_skill_projection_source_rule_version_id_fkey FOREIGN KEY (source_rule_version_id) REFERENCES mathprep.adaptation_rule_versions(id) ON DELETE RESTRICT;


--
-- Name: learners learners_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learners
    ADD CONSTRAINT learners_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE CASCADE;


--
-- Name: learners learners_tenant_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.learners
    ADD CONSTRAINT learners_tenant_fk FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: pack_access_tokens pack_access_tokens_extended_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_access_tokens
    ADD CONSTRAINT pack_access_tokens_extended_by_parent_id_fkey FOREIGN KEY (extended_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: pack_access_tokens pack_access_tokens_extension_command_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_access_tokens
    ADD CONSTRAINT pack_access_tokens_extension_command_id_fkey FOREIGN KEY (extension_command_id) REFERENCES mathprep.parent_command_receipts(command_id) ON DELETE RESTRICT;


--
-- Name: pack_access_tokens pack_access_tokens_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_access_tokens
    ADD CONSTRAINT pack_access_tokens_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: pack_artifacts pack_artifacts_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_artifacts
    ADD CONSTRAINT pack_artifacts_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: pack_item_skills pack_item_skills_pack_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_skills
    ADD CONSTRAINT pack_item_skills_pack_item_id_fkey FOREIGN KEY (pack_item_id) REFERENCES mathprep.pack_items(id) ON DELETE CASCADE;


--
-- Name: pack_item_skills pack_item_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_skills
    ADD CONSTRAINT pack_item_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: pack_item_voids pack_item_voids_incident_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_voids
    ADD CONSTRAINT pack_item_voids_incident_id_fkey FOREIGN KEY (incident_id) REFERENCES mathprep.content_incidents(id) ON DELETE RESTRICT;


--
-- Name: pack_item_voids pack_item_voids_pack_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_item_voids
    ADD CONSTRAINT pack_item_voids_pack_item_id_fkey FOREIGN KEY (pack_item_id) REFERENCES mathprep.pack_items(id) ON DELETE CASCADE;


--
-- Name: pack_items pack_items_item_instance_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_item_instance_id_fkey FOREIGN KEY (item_instance_id) REFERENCES mathprep.item_instances(id) ON DELETE RESTRICT;


--
-- Name: pack_items pack_items_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: pack_items pack_items_primary_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_primary_skill_id_fkey FOREIGN KEY (primary_skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: pack_items pack_items_source_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_source_item_id_fkey FOREIGN KEY (source_item_id) REFERENCES mathprep.items(id) ON DELETE RESTRICT;


--
-- Name: pack_items pack_items_source_item_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_items
    ADD CONSTRAINT pack_items_source_item_version_id_fkey FOREIGN KEY (source_item_version_id) REFERENCES mathprep.item_versions(id) ON DELETE RESTRICT;


--
-- Name: pack_lifecycle_events pack_lifecycle_events_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.pack_lifecycle_events
    ADD CONSTRAINT pack_lifecycle_events_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: packs packs_curriculum_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES mathprep.curriculum_versions(id) ON DELETE RESTRICT;


--
-- Name: packs packs_profile_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_profile_id_parent_id_fkey FOREIGN KEY (profile_id, parent_id) REFERENCES mathprep.learner_profiles(id, parent_id) ON DELETE CASCADE;


--
-- Name: packs packs_rule_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_rule_version_id_fkey FOREIGN KEY (rule_version_id) REFERENCES mathprep.adaptation_rule_versions(id) ON DELETE RESTRICT;


--
-- Name: packs packs_tenant_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.packs
    ADD CONSTRAINT packs_tenant_fk FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: parent_active_profiles parent_active_profiles_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_active_profiles
    ADD CONSTRAINT parent_active_profiles_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE CASCADE;


--
-- Name: parent_active_profiles parent_active_profiles_profile_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_active_profiles
    ADD CONSTRAINT parent_active_profiles_profile_id_parent_id_fkey FOREIGN KEY (profile_id, parent_id) REFERENCES mathprep.learner_profiles(id, parent_id) ON DELETE CASCADE;


--
-- Name: parent_command_receipts parent_command_receipts_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_command_receipts
    ADD CONSTRAINT parent_command_receipts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: parent_command_receipts parent_command_receipts_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_command_receipts
    ADD CONSTRAINT parent_command_receipts_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: parent_consents parent_consents_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parent_consents
    ADD CONSTRAINT parent_consents_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE CASCADE;


--
-- Name: parents parents_tenant_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.parents
    ADD CONSTRAINT parents_tenant_fk FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: phone_identity phone_identity_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.phone_identity
    ADD CONSTRAINT phone_identity_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_accounts platform_accounts_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_accounts
    ADD CONSTRAINT platform_accounts_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_checkouts platform_checkouts_actor_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_checkouts
    ADD CONSTRAINT platform_checkouts_actor_principal_id_fkey FOREIGN KEY (actor_principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_checkouts platform_checkouts_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_checkouts
    ADD CONSTRAINT platform_checkouts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id);


--
-- Name: platform_children platform_children_learner_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_learner_id_fkey FOREIGN KEY (learner_id) REFERENCES mathprep.learners(id);


--
-- Name: platform_children platform_children_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_children platform_children_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_children
    ADD CONSTRAINT platform_children_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id);


--
-- Name: platform_classes platform_classes_school_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_classes
    ADD CONSTRAINT platform_classes_school_id_fkey FOREIGN KEY (school_id) REFERENCES mathprep.platform_schools(id);


--
-- Name: platform_external_identities platform_external_identities_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_external_identities
    ADD CONSTRAINT platform_external_identities_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_join_requests platform_join_requests_child_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_join_requests
    ADD CONSTRAINT platform_join_requests_child_id_fkey FOREIGN KEY (child_id) REFERENCES mathprep.platform_children(id);


--
-- Name: platform_join_requests platform_join_requests_class_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_join_requests
    ADD CONSTRAINT platform_join_requests_class_id_fkey FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id);


--
-- Name: platform_join_requests platform_join_requests_decided_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_join_requests
    ADD CONSTRAINT platform_join_requests_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_join_requests platform_join_requests_requested_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_join_requests
    ADD CONSTRAINT platform_join_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_learning_answers platform_learning_answers_session_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_answers
    ADD CONSTRAINT platform_learning_answers_session_id_fkey FOREIGN KEY (session_id) REFERENCES mathprep.platform_learning_sessions(id);


--
-- Name: platform_learning_capabilities platform_learning_capabilities_session_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_capabilities
    ADD CONSTRAINT platform_learning_capabilities_session_id_fkey FOREIGN KEY (session_id) REFERENCES mathprep.platform_learning_sessions(id);


--
-- Name: platform_learning_drafts platform_learning_drafts_session_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_drafts
    ADD CONSTRAINT platform_learning_drafts_session_id_fkey FOREIGN KEY (session_id) REFERENCES mathprep.platform_learning_sessions(id);


--
-- Name: platform_learning_events platform_learning_events_session_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_events
    ADD CONSTRAINT platform_learning_events_session_id_fkey FOREIGN KEY (session_id) REFERENCES mathprep.platform_learning_sessions(id);


--
-- Name: platform_learning_sessions platform_learning_sessions_child_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_child_id_fkey FOREIGN KEY (child_id) REFERENCES mathprep.platform_children(id);


--
-- Name: platform_learning_sessions platform_learning_sessions_self_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_self_profile_id_fkey FOREIGN KEY (self_profile_id) REFERENCES mathprep.platform_student_self_profile(profile_id) ON DELETE RESTRICT;


--
-- Name: platform_learning_sessions platform_learning_sessions_test_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_learning_sessions
    ADD CONSTRAINT platform_learning_sessions_test_id_fkey FOREIGN KEY (test_id) REFERENCES mathprep.platform_tests(id);


--
-- Name: platform_license_requests platform_license_requests_decided_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_license_requests
    ADD CONSTRAINT platform_license_requests_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_license_requests platform_license_requests_requested_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_license_requests
    ADD CONSTRAINT platform_license_requests_requested_by_fkey FOREIGN KEY (requested_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_license_requests platform_license_requests_school_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_license_requests
    ADD CONSTRAINT platform_license_requests_school_id_fkey FOREIGN KEY (school_id) REFERENCES mathprep.platform_schools(id);


--
-- Name: platform_login_intent platform_login_intent_membership_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_login_intent
    ADD CONSTRAINT platform_login_intent_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES mathprep.access_memberships(id) ON DELETE RESTRICT;


--
-- Name: platform_login_intent platform_login_intent_phone_identity_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_login_intent
    ADD CONSTRAINT platform_login_intent_phone_identity_id_fkey FOREIGN KEY (phone_identity_id) REFERENCES mathprep.phone_identity(phone_identity_id) ON DELETE RESTRICT;


--
-- Name: platform_login_intent platform_login_intent_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_login_intent
    ADD CONSTRAINT platform_login_intent_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_notifications platform_notifications_class_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_class_id_fkey FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id);


--
-- Name: platform_notifications platform_notifications_recipient_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_recipient_principal_id_fkey FOREIGN KEY (recipient_principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_notifications platform_notifications_reference_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES mathprep.platform_join_requests(id);


--
-- Name: platform_notifications platform_notifications_session_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_session_id_fkey FOREIGN KEY (session_id) REFERENCES mathprep.platform_learning_sessions(id) ON DELETE RESTRICT;


--
-- Name: platform_notifications platform_notifications_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_notifications
    ADD CONSTRAINT platform_notifications_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id);


--
-- Name: platform_password_recovery_intent platform_password_recovery_intent_phone_identity_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_password_recovery_intent
    ADD CONSTRAINT platform_password_recovery_intent_phone_identity_id_fkey FOREIGN KEY (phone_identity_id) REFERENCES mathprep.phone_identity(phone_identity_id) ON DELETE RESTRICT;


--
-- Name: platform_password_recovery_intent platform_password_recovery_intent_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_password_recovery_intent
    ADD CONSTRAINT platform_password_recovery_intent_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_placements platform_placements_child_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_placements
    ADD CONSTRAINT platform_placements_child_id_fkey FOREIGN KEY (child_id) REFERENCES mathprep.platform_children(id);


--
-- Name: platform_placements platform_placements_class_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_placements
    ADD CONSTRAINT platform_placements_class_id_fkey FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id);


--
-- Name: platform_push_outbox platform_push_outbox_notification_identity_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_outbox
    ADD CONSTRAINT platform_push_outbox_notification_identity_fkey FOREIGN KEY (notification_id, recipient_principal_id, event_kind) REFERENCES mathprep.platform_notifications(id, recipient_principal_id, kind) ON DELETE RESTRICT;


--
-- Name: platform_push_preferences platform_push_preferences_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_preferences
    ADD CONSTRAINT platform_push_preferences_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE CASCADE;


--
-- Name: platform_push_subscriptions platform_push_subscriptions_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_push_subscriptions
    ADD CONSTRAINT platform_push_subscriptions_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE CASCADE;


--
-- Name: platform_registration_intent platform_registration_intent_finalized_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_registration_intent
    ADD CONSTRAINT platform_registration_intent_finalized_principal_id_fkey FOREIGN KEY (finalized_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_schools platform_schools_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_schools
    ADD CONSTRAINT platform_schools_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id);


--
-- Name: platform_sessions platform_sessions_membership_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_sessions
    ADD CONSTRAINT platform_sessions_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES mathprep.access_memberships(id);


--
-- Name: platform_sessions platform_sessions_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_sessions
    ADD CONSTRAINT platform_sessions_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.platform_accounts(principal_id);


--
-- Name: platform_staff_requests platform_staff_requests_decided_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_staff_requests
    ADD CONSTRAINT platform_staff_requests_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_staff_requests platform_staff_requests_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_staff_requests
    ADD CONSTRAINT platform_staff_requests_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_staff_requests platform_staff_requests_school_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_staff_requests
    ADD CONSTRAINT platform_staff_requests_school_id_fkey FOREIGN KEY (school_id) REFERENCES mathprep.platform_schools(id);


--
-- Name: platform_student_access_intent platform_student_access_intent_child_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_child_id_fkey FOREIGN KEY (child_id) REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT;


--
-- Name: platform_student_access_intent platform_student_access_intent_child_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_child_principal_id_fkey FOREIGN KEY (child_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_student_access_intent platform_student_access_intent_guardian_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_guardian_principal_id_fkey FOREIGN KEY (guardian_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_student_access_intent platform_student_access_intent_guardian_relationship_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_guardian_relationship_id_fkey FOREIGN KEY (guardian_relationship_id) REFERENCES mathprep.access_guardian_relationships(id) ON DELETE RESTRICT;


--
-- Name: platform_student_access_intent platform_student_access_intent_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_access_intent
    ADD CONSTRAINT platform_student_access_intent_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: platform_student_phone_enrollment_intent platform_student_phone_enrollment_intent_membership_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_phone_enrollment_intent
    ADD CONSTRAINT platform_student_phone_enrollment_intent_membership_id_fkey FOREIGN KEY (membership_id) REFERENCES mathprep.access_memberships(id) ON DELETE RESTRICT;


--
-- Name: platform_student_phone_enrollment_intent platform_student_phone_enrollment_intent_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_phone_enrollment_intent
    ADD CONSTRAINT platform_student_phone_enrollment_intent_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_student_profile_link platform_student_profile_link_child_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_profile_link
    ADD CONSTRAINT platform_student_profile_link_child_id_fkey FOREIGN KEY (child_id) REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT;


--
-- Name: platform_student_profile_link platform_student_profile_link_family_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_profile_link
    ADD CONSTRAINT platform_student_profile_link_family_tenant_id_fkey FOREIGN KEY (family_tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: platform_student_profile_link platform_student_profile_link_student_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_profile_link
    ADD CONSTRAINT platform_student_profile_link_student_principal_id_fkey FOREIGN KEY (student_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_student_profile_link platform_student_profile_link_student_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_profile_link
    ADD CONSTRAINT platform_student_profile_link_student_tenant_id_fkey FOREIGN KEY (student_tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: platform_student_self_profile platform_student_self_profile_engine_student_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_engine_student_id_fkey FOREIGN KEY (engine_student_id) REFERENCES public.students(user_id) ON DELETE RESTRICT;


--
-- Name: platform_student_self_profile platform_student_self_profile_student_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_student_principal_id_fkey FOREIGN KEY (student_principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: platform_student_self_profile platform_student_self_profile_student_tenant_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_student_self_profile
    ADD CONSTRAINT platform_student_self_profile_student_tenant_id_fkey FOREIGN KEY (student_tenant_id) REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT;


--
-- Name: platform_teacher_classes platform_teacher_classes_class_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_teacher_classes
    ADD CONSTRAINT platform_teacher_classes_class_id_fkey FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id);


--
-- Name: platform_teacher_classes platform_teacher_classes_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_teacher_classes
    ADD CONSTRAINT platform_teacher_classes_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_tests platform_tests_class_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_tests
    ADD CONSTRAINT platform_tests_class_id_fkey FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id);


--
-- Name: platform_tests platform_tests_created_by_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_tests
    ADD CONSTRAINT platform_tests_created_by_fkey FOREIGN KEY (created_by) REFERENCES mathprep.access_principals(id);


--
-- Name: platform_trusted_device platform_trusted_device_principal_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.platform_trusted_device
    ADD CONSTRAINT platform_trusted_device_principal_id_fkey FOREIGN KEY (principal_id) REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT;


--
-- Name: profile_level_history profile_level_history_created_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_level_history
    ADD CONSTRAINT profile_level_history_created_by_parent_id_fkey FOREIGN KEY (created_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: profile_level_history profile_level_history_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_level_history
    ADD CONSTRAINT profile_level_history_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: profile_level_history profile_level_history_rule_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_level_history
    ADD CONSTRAINT profile_level_history_rule_version_id_fkey FOREIGN KEY (rule_version_id) REFERENCES mathprep.adaptation_rule_versions(id) ON DELETE RESTRICT;


--
-- Name: profile_pauses profile_pauses_created_by_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_pauses
    ADD CONSTRAINT profile_pauses_created_by_parent_id_fkey FOREIGN KEY (created_by_parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: profile_pauses profile_pauses_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_pauses
    ADD CONSTRAINT profile_pauses_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: profile_schedules profile_schedules_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.profile_schedules
    ADD CONSTRAINT profile_schedules_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: restore_drills restore_drills_backup_run_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.restore_drills
    ADD CONSTRAINT restore_drills_backup_run_id_fkey FOREIGN KEY (backup_run_id) REFERENCES mathprep.backup_runs(id) ON DELETE RESTRICT;


--
-- Name: retake_authorizations retake_authorizations_pack_id_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.retake_authorizations
    ADD CONSTRAINT retake_authorizations_pack_id_parent_id_fkey FOREIGN KEY (pack_id, parent_id) REFERENCES mathprep.packs(id, parent_id) ON DELETE CASCADE;


--
-- Name: skill_event_exclusions skill_event_exclusions_skill_event_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_event_exclusions
    ADD CONSTRAINT skill_event_exclusions_skill_event_id_fkey FOREIGN KEY (skill_event_id) REFERENCES mathprep.skill_events(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_attempt_answer_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_attempt_answer_id_fkey FOREIGN KEY (attempt_answer_id) REFERENCES mathprep.attempt_answers(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_attempt_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_attempt_id_fkey FOREIGN KEY (attempt_id) REFERENCES mathprep.attempts(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_pack_item_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_pack_item_id_fkey FOREIGN KEY (pack_item_id) REFERENCES mathprep.pack_items(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_profile_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES mathprep.learner_profiles(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_rule_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_rule_version_id_fkey FOREIGN KEY (rule_version_id) REFERENCES mathprep.adaptation_rule_versions(id) ON DELETE RESTRICT;


--
-- Name: skill_events skill_events_score_revision_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_score_revision_id_fkey FOREIGN KEY (score_revision_id) REFERENCES mathprep.attempt_score_revisions(id) ON DELETE CASCADE;


--
-- Name: skill_events skill_events_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_events
    ADD CONSTRAINT skill_events_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: skill_prerequisites skill_prerequisites_prerequisite_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_prerequisites
    ADD CONSTRAINT skill_prerequisites_prerequisite_skill_id_fkey FOREIGN KEY (prerequisite_skill_id) REFERENCES mathprep.skills(id) ON DELETE RESTRICT;


--
-- Name: skill_prerequisites skill_prerequisites_skill_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skill_prerequisites
    ADD CONSTRAINT skill_prerequisites_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES mathprep.skills(id) ON DELETE CASCADE;


--
-- Name: skills skills_topic_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.skills
    ADD CONSTRAINT skills_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES mathprep.topics(id) ON DELETE RESTRICT;


--
-- Name: telegram_delivery_attempts telegram_delivery_attempts_job_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_delivery_attempts
    ADD CONSTRAINT telegram_delivery_attempts_job_id_fkey FOREIGN KEY (job_id) REFERENCES mathprep.jobs(id) ON DELETE CASCADE;


--
-- Name: telegram_delivery_attempts telegram_delivery_attempts_pack_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_delivery_attempts
    ADD CONSTRAINT telegram_delivery_attempts_pack_id_fkey FOREIGN KEY (pack_id) REFERENCES mathprep.packs(id) ON DELETE CASCADE;


--
-- Name: telegram_delivery_attempts telegram_delivery_attempts_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_delivery_attempts
    ADD CONSTRAINT telegram_delivery_attempts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: telegram_update_receipts telegram_update_receipts_parent_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.telegram_update_receipts
    ADD CONSTRAINT telegram_update_receipts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES mathprep.parents(id) ON DELETE RESTRICT;


--
-- Name: topics topics_curriculum_language_fk; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.topics
    ADD CONSTRAINT topics_curriculum_language_fk FOREIGN KEY (curriculum_version_id, language_code) REFERENCES mathprep.curriculum_versions(id, language_code) ON DELETE RESTRICT;


--
-- Name: topics topics_curriculum_version_id_fkey; Type: FK CONSTRAINT; Schema: mathprep; Owner: -
--

ALTER TABLE ONLY mathprep.topics
    ADD CONSTRAINT topics_curriculum_version_id_fkey FOREIGN KEY (curriculum_version_id) REFERENCES mathprep.curriculum_versions(id) ON DELETE RESTRICT;


--
-- Name: billing_order_child billing_order_child_order_id_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_order_child
    ADD CONSTRAINT billing_order_child_order_id_tenant_id_fkey FOREIGN KEY (order_id, tenant_id) REFERENCES public.billing_order(order_id, tenant_id) ON DELETE RESTRICT;


--
-- Name: cas_evaluation_request cas_evaluation_request_operation_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_operation_type_fkey FOREIGN KEY (operation_type) REFERENCES public.cas_operation_type(code);


--
-- Name: cas_evaluation_request cas_evaluation_request_reason_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_reason_code_fkey FOREIGN KEY (reason_code) REFERENCES public.reason_code(code);


--
-- Name: cas_evaluation_request cas_evaluation_request_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.users(user_id);


--
-- Name: cas_evaluation_request cas_evaluation_request_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_status_fkey FOREIGN KEY (status) REFERENCES public.cas_evaluation_status(code);


--
-- Name: cas_evaluation_request cas_evaluation_request_verdict_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_evaluation_request
    ADD CONSTRAINT cas_evaluation_request_verdict_fkey FOREIGN KEY (verdict) REFERENCES public.verdict(code);


--
-- Name: cas_submission cas_submission_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_submission
    ADD CONSTRAINT cas_submission_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.task_instance(item_id);


--
-- Name: cas_submission cas_submission_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_submission
    ADD CONSTRAINT cas_submission_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(user_id);


--
-- Name: cas_submission cas_submission_submission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_submission
    ADD CONSTRAINT cas_submission_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.cas_evaluation_request(request_id);


--
-- Name: child_entitlement_period child_entitlement_period_order_id_tenant_id_child_profile__fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.child_entitlement_period
    ADD CONSTRAINT child_entitlement_period_order_id_tenant_id_child_profile__fkey FOREIGN KEY (order_id, tenant_id, child_profile_id) REFERENCES public.billing_order_child(order_id, tenant_id, child_profile_id) ON DELETE RESTRICT;


--
-- Name: event_log event_log_event_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.event_log
    ADD CONSTRAINT event_log_event_type_fkey FOREIGN KEY (event_type) REFERENCES public.event_type(code);


--
-- Name: generation_request generation_request_locale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_request
    ADD CONSTRAINT generation_request_locale_fkey FOREIGN KEY (locale) REFERENCES public.locale(code);


--
-- Name: generation_request generation_request_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generation_request
    ADD CONSTRAINT generation_request_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(user_id);


--
-- Name: mastery_topic mastery_topic_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastery_topic
    ADD CONSTRAINT mastery_topic_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(code);


--
-- Name: mastery_topic mastery_topic_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastery_topic
    ADD CONSTRAINT mastery_topic_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(user_id);


--
-- Name: mastery_topic mastery_topic_tier_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mastery_topic
    ADD CONSTRAINT mastery_topic_tier_fkey FOREIGN KEY (tier) REFERENCES public.tier_code(code);


--
-- Name: payment_attempt payment_attempt_order_id_tenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_attempt
    ADD CONSTRAINT payment_attempt_order_id_tenant_id_fkey FOREIGN KEY (order_id, tenant_id) REFERENCES public.billing_order(order_id, tenant_id) ON DELETE RESTRICT;


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: submission submission_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.task_instance(item_id);


--
-- Name: submission submission_reason_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_reason_code_fkey FOREIGN KEY (reason_code) REFERENCES public.reason_code(code);


--
-- Name: submission submission_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(user_id);


--
-- Name: submission submission_verdict_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.submission
    ADD CONSTRAINT submission_verdict_fkey FOREIGN KEY (verdict) REFERENCES public.verdict(code);


--
-- Name: task_instance task_instance_locale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_locale_fkey FOREIGN KEY (locale) REFERENCES public.locale(code);


--
-- Name: task_instance task_instance_render_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_render_target_fkey FOREIGN KEY (render_target) REFERENCES public.render_target(code);


--
-- Name: task_instance task_instance_task_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_task_set_id_fkey FOREIGN KEY (task_set_id) REFERENCES public.task_set(task_set_id);


--
-- Name: task_instance task_instance_tier_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_tier_fkey FOREIGN KEY (tier) REFERENCES public.tier_code(code);


--
-- Name: task_instance task_instance_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_instance
    ADD CONSTRAINT task_instance_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.task_type(type_id);


--
-- Name: task_set task_set_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_set
    ADD CONSTRAINT task_set_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.generation_request(request_id);


--
-- Name: task_set task_set_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_set
    ADD CONSTRAINT task_set_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(user_id);


--
-- Name: task_type task_type_answer_widget_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_answer_widget_fkey FOREIGN KEY (answer_widget) REFERENCES public.answer_widget(code);


--
-- Name: task_type task_type_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(code);


--
-- Name: task_type task_type_equivalence_policy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_equivalence_policy_fkey FOREIGN KEY (equivalence_policy) REFERENCES public.equivalence_policy(code);


--
-- Name: task_type task_type_generation_mode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_generation_mode_fkey FOREIGN KEY (generation_mode) REFERENCES public.generation_mode(code);


--
-- Name: task_type task_type_grade_band_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_grade_band_fk FOREIGN KEY (grade) REFERENCES public.grade_band(code);


--
-- Name: task_type task_type_locale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_locale_fkey FOREIGN KEY (locale) REFERENCES public.locale(code);


--
-- Name: task_type task_type_status_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_status_fkey FOREIGN KEY (status) REFERENCES public.task_type_status(code);


--
-- Name: task_type_template task_type_template_locale_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type_template
    ADD CONSTRAINT task_type_template_locale_fkey FOREIGN KEY (locale) REFERENCES public.locale(code);


--
-- Name: task_type_template task_type_template_render_target_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type_template
    ADD CONSTRAINT task_type_template_render_target_fkey FOREIGN KEY (render_target) REFERENCES public.render_target(code);


--
-- Name: task_type_template task_type_template_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type_template
    ADD CONSTRAINT task_type_template_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.task_type(type_id) ON DELETE CASCADE;


--
-- Name: task_type task_type_validation_method_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.task_type
    ADD CONSTRAINT task_type_validation_method_fkey FOREIGN KEY (validation_method) REFERENCES public.validation_method(code);


--
-- Name: users users_user_type_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_user_type_fkey FOREIGN KEY (user_type) REFERENCES public.user_type(code);


--
-- Name: verified_provider_event verified_provider_event_payment_attempt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verified_provider_event
    ADD CONSTRAINT verified_provider_event_payment_attempt_id_fkey FOREIGN KEY (payment_attempt_id) REFERENCES public.payment_attempt(payment_attempt_id) ON DELETE RESTRICT;


--
-- Name: SCHEMA mathprep; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA mathprep TO mathprep_app;
GRANT USAGE ON SCHEMA mathprep TO mathprep_platform_local;
GRANT USAGE ON SCHEMA mathprep TO mathprep_notifications_svc;
GRANT USAGE ON SCHEMA mathprep TO platform_api_svc;
GRANT USAGE ON SCHEMA mathprep TO platform_auth_retention_svc;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO taskgen_svc;
GRANT USAGE ON SCHEMA public TO grader_svc;
GRANT USAGE ON SCHEMA public TO cas_svc;
GRANT USAGE ON SCHEMA public TO platform_api_svc;


--
-- Name: FUNCTION assert_student_access_intent_scope(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.assert_student_access_intent_scope() FROM PUBLIC;


--
-- Name: FUNCTION assert_student_phone_enrollment_scope(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.assert_student_phone_enrollment_scope() FROM PUBLIC;


--
-- Name: FUNCTION assert_student_profile_link_scope(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.assert_student_profile_link_scope() FROM PUBLIC;


--
-- Name: FUNCTION assert_student_self_profile_owner(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.assert_student_self_profile_owner() FROM PUBLIC;


--
-- Name: FUNCTION guard_student_access_intent_transition(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.guard_student_access_intent_transition() FROM PUBLIC;


--
-- Name: FUNCTION guard_student_phone_enrollment_transition(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.guard_student_phone_enrollment_transition() FROM PUBLIC;


--
-- Name: FUNCTION guard_student_profile_link_transition(); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.guard_student_profile_link_transition() FROM PUBLIC;


--
-- Name: FUNCTION prune_platform_preauth_state(batch_size integer); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.prune_platform_preauth_state(batch_size integer) FROM PUBLIC;
GRANT ALL ON FUNCTION mathprep.prune_platform_preauth_state(batch_size integer) TO platform_api_svc;


--
-- Name: FUNCTION prune_platform_student_access_intents(batch_size integer); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.prune_platform_student_access_intents(batch_size integer) FROM PUBLIC;
GRANT ALL ON FUNCTION mathprep.prune_platform_student_access_intents(batch_size integer) TO platform_api_svc;


--
-- Name: FUNCTION prune_platform_student_phone_enrollment_intents(batch_size integer); Type: ACL; Schema: mathprep; Owner: -
--

REVOKE ALL ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(batch_size integer) FROM PUBLIC;
GRANT ALL ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(batch_size integer) TO platform_api_svc;


--
-- Name: TABLE access_audit_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_audit_events TO mathprep_app;
GRANT SELECT,INSERT ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(id) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(id) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(tenant_id) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(tenant_id) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.event_type; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(event_type) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(event_type) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.actor_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(actor_principal_id) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(actor_principal_id) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.correlation_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(correlation_id) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(correlation_id) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: COLUMN access_audit_events.safe_payload; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(safe_payload) ON TABLE mathprep.access_audit_events TO platform_api_svc;
GRANT INSERT(safe_payload) ON TABLE mathprep.access_audit_events TO mathprep_platform_local;


--
-- Name: TABLE access_consents; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_consents TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_consents TO mathprep_platform_local;


--
-- Name: TABLE access_external_identities; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_external_identities TO mathprep_app;


--
-- Name: TABLE access_guardian_relationships; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_guardian_relationships TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_guardian_relationships TO mathprep_platform_local;


--
-- Name: COLUMN access_guardian_relationships.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(tenant_id) ON TABLE mathprep.access_guardian_relationships TO platform_api_svc;


--
-- Name: COLUMN access_guardian_relationships.guardian_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(guardian_principal_id) ON TABLE mathprep.access_guardian_relationships TO platform_api_svc;


--
-- Name: COLUMN access_guardian_relationships.learner_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(learner_id) ON TABLE mathprep.access_guardian_relationships TO platform_api_svc;


--
-- Name: COLUMN access_guardian_relationships.state; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(state) ON TABLE mathprep.access_guardian_relationships TO platform_api_svc;


--
-- Name: TABLE access_invitations; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_invitations TO mathprep_app;


--
-- Name: TABLE access_legacy_parent_mappings; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_legacy_parent_mappings TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_legacy_parent_mappings TO mathprep_platform_local;


--
-- Name: TABLE access_memberships; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_memberships TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_memberships TO mathprep_platform_local;


--
-- Name: COLUMN access_memberships.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(tenant_id) ON TABLE mathprep.access_memberships TO platform_api_svc;


--
-- Name: COLUMN access_memberships.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(principal_id) ON TABLE mathprep.access_memberships TO platform_api_svc;


--
-- Name: COLUMN access_memberships.role; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(role) ON TABLE mathprep.access_memberships TO platform_api_svc;


--
-- Name: COLUMN access_memberships.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.access_memberships TO platform_api_svc;


--
-- Name: TABLE access_principals; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_principals TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_principals TO mathprep_platform_local;
GRANT SELECT ON TABLE mathprep.access_principals TO mathprep_notifications_svc;


--
-- Name: COLUMN access_principals.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.access_principals TO platform_api_svc;


--
-- Name: COLUMN access_principals.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.access_principals TO platform_api_svc;


--
-- Name: TABLE access_recovery_cases; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_recovery_cases TO mathprep_app;


--
-- Name: TABLE access_tenants; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.access_tenants TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.access_tenants TO mathprep_platform_local;


--
-- Name: COLUMN access_tenants.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.access_tenants TO platform_api_svc;


--
-- Name: COLUMN access_tenants.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.access_tenants TO platform_api_svc;


--
-- Name: TABLE adaptation_rule_versions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.adaptation_rule_versions TO mathprep_app;


--
-- Name: TABLE answer_evaluation_revisions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.answer_evaluation_revisions TO mathprep_app;


--
-- Name: TABLE assistance_marks; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.assistance_marks TO mathprep_app;


--
-- Name: TABLE attempt_answers; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.attempt_answers TO mathprep_app;


--
-- Name: TABLE attempt_score_revisions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.attempt_score_revisions TO mathprep_app;


--
-- Name: TABLE attempts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.attempts TO mathprep_app;


--
-- Name: TABLE backup_artifact_manifests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.backup_artifact_manifests TO mathprep_app;


--
-- Name: TABLE backup_runs; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.backup_runs TO mathprep_app;


--
-- Name: TABLE content_decision_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_decision_events TO mathprep_app;


--
-- Name: TABLE content_incident_pack_items; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_incident_pack_items TO mathprep_app;


--
-- Name: TABLE content_incidents; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_incidents TO mathprep_app;


--
-- Name: TABLE content_readiness_run_days; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_readiness_run_days TO mathprep_app;


--
-- Name: TABLE content_readiness_runs; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_readiness_runs TO mathprep_app;


--
-- Name: TABLE content_reports; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.content_reports TO mathprep_app;


--
-- Name: TABLE curriculum_versions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.curriculum_versions TO mathprep_app;


--
-- Name: TABLE deletion_requests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.deletion_requests TO mathprep_app;


--
-- Name: TABLE difficulty_override_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.difficulty_override_events TO mathprep_app;


--
-- Name: TABLE difficulty_overrides; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.difficulty_overrides TO mathprep_app;


--
-- Name: TABLE item_instances; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.item_instances TO mathprep_app;


--
-- Name: TABLE item_version_skills; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.item_version_skills TO mathprep_app;


--
-- Name: TABLE item_versions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.item_versions TO mathprep_app;


--
-- Name: TABLE items; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.items TO mathprep_app;


--
-- Name: TABLE job_attempts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.job_attempts TO mathprep_app;


--
-- Name: TABLE jobs; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.jobs TO mathprep_app;


--
-- Name: TABLE learner_profiles; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.learner_profiles TO mathprep_app;


--
-- Name: TABLE learner_skill_projection; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.learner_skill_projection TO mathprep_app;


--
-- Name: TABLE learners; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.learners TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.learners TO mathprep_platform_local;


--
-- Name: TABLE operation_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.operation_events TO mathprep_app;


--
-- Name: TABLE pack_access_tokens; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_access_tokens TO mathprep_app;


--
-- Name: TABLE pack_artifacts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_artifacts TO mathprep_app;


--
-- Name: TABLE pack_item_skills; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_item_skills TO mathprep_app;


--
-- Name: TABLE pack_item_voids; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_item_voids TO mathprep_app;


--
-- Name: TABLE pack_items; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_items TO mathprep_app;


--
-- Name: TABLE pack_lifecycle_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.pack_lifecycle_events TO mathprep_app;


--
-- Name: TABLE packs; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.packs TO mathprep_app;


--
-- Name: TABLE parent_active_profiles; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.parent_active_profiles TO mathprep_app;


--
-- Name: TABLE parent_command_receipts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.parent_command_receipts TO mathprep_app;


--
-- Name: TABLE parent_consents; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.parent_consents TO mathprep_app;


--
-- Name: TABLE parents; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.parents TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.parents TO mathprep_platform_local;


--
-- Name: COLUMN phone_identity.phone_identity_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(phone_identity_id),INSERT(phone_identity_id) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: COLUMN phone_identity.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(principal_id),INSERT(principal_id) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: COLUMN phone_identity.phone_e164; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(phone_e164),INSERT(phone_e164) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: COLUMN phone_identity.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status),INSERT(status),UPDATE(status) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: COLUMN phone_identity.verified_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(verified_at),UPDATE(verified_at) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: COLUMN phone_identity.revoked_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(revoked_at) ON TABLE mathprep.phone_identity TO platform_api_svc;


--
-- Name: TABLE platform_accounts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_accounts TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_accounts TO mathprep_platform_local;


--
-- Name: COLUMN platform_accounts.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(principal_id) ON TABLE mathprep.platform_accounts TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_accounts.email; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(email) ON TABLE mathprep.platform_accounts TO platform_api_svc;


--
-- Name: COLUMN platform_accounts.password_hash; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(password_hash) ON TABLE mathprep.platform_accounts TO platform_api_svc;


--
-- Name: COLUMN platform_accounts.name; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(name) ON TABLE mathprep.platform_accounts TO platform_api_svc;


--
-- Name: COLUMN platform_accounts.locale; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(locale) ON TABLE mathprep.platform_accounts TO platform_api_svc;
GRANT SELECT(locale) ON TABLE mathprep.platform_accounts TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_accounts.email_verified_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(email_verified_at),INSERT(email_verified_at),UPDATE(email_verified_at) ON TABLE mathprep.platform_accounts TO platform_api_svc;


--
-- Name: TABLE platform_checkouts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_checkouts TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_checkouts TO mathprep_platform_local;


--
-- Name: TABLE platform_children; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_children TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_children TO mathprep_platform_local;


--
-- Name: COLUMN platform_children.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_children TO platform_api_svc;


--
-- Name: COLUMN platform_children.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(tenant_id) ON TABLE mathprep.platform_children TO platform_api_svc;


--
-- Name: COLUMN platform_children.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(principal_id) ON TABLE mathprep.platform_children TO platform_api_svc;


--
-- Name: COLUMN platform_children.learner_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(learner_id) ON TABLE mathprep.platform_children TO platform_api_svc;


--
-- Name: COLUMN platform_children.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.platform_children TO platform_api_svc;


--
-- Name: TABLE platform_classes; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_classes TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_classes TO mathprep_platform_local;


--
-- Name: COLUMN platform_classes.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_classes TO platform_api_svc;


--
-- Name: COLUMN platform_classes.school_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(school_id) ON TABLE mathprep.platform_classes TO platform_api_svc;


--
-- Name: COLUMN platform_classes.name; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(name) ON TABLE mathprep.platform_classes TO platform_api_svc;


--
-- Name: COLUMN platform_classes.grade; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(grade) ON TABLE mathprep.platform_classes TO platform_api_svc;


--
-- Name: TABLE platform_external_identities; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT ON TABLE mathprep.platform_external_identities TO platform_api_svc;


--
-- Name: TABLE platform_join_requests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_join_requests TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_join_requests TO mathprep_platform_local;


--
-- Name: COLUMN platform_join_requests.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_join_requests TO platform_api_svc;


--
-- Name: COLUMN platform_join_requests.child_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(child_id) ON TABLE mathprep.platform_join_requests TO platform_api_svc;


--
-- Name: COLUMN platform_join_requests.class_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(class_id) ON TABLE mathprep.platform_join_requests TO platform_api_svc;


--
-- Name: TABLE platform_learning_answers; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_learning_answers TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_learning_answers TO mathprep_platform_local;


--
-- Name: TABLE platform_learning_capabilities; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_learning_capabilities TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_learning_capabilities TO mathprep_platform_local;


--
-- Name: TABLE platform_learning_drafts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_learning_drafts TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_learning_drafts TO mathprep_platform_local;


--
-- Name: TABLE platform_learning_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_learning_events TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_learning_events TO mathprep_platform_local;


--
-- Name: TABLE platform_learning_sessions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_learning_sessions TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_learning_sessions TO mathprep_platform_local;


--
-- Name: COLUMN platform_learning_sessions.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.child_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(child_id) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.mode; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(mode) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.test_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(test_id) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.finished_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(finished_at) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;


--
-- Name: COLUMN platform_learning_sessions.self_profile_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(self_profile_id) ON TABLE mathprep.platform_learning_sessions TO platform_api_svc;
GRANT INSERT(self_profile_id) ON TABLE mathprep.platform_learning_sessions TO mathprep_platform_local;


--
-- Name: TABLE platform_license_requests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_license_requests TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_license_requests TO mathprep_platform_local;


--
-- Name: TABLE platform_login_intent; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_login_intent TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_login_intent TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_login_intent.intent_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(intent_id) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(principal_id) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.membership_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(membership_id) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.phone_identity_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(phone_identity_id) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.device_binding; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_binding) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.device_token_digest; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_token_digest),UPDATE(device_token_digest) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: COLUMN platform_login_intent.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_login_intent TO platform_api_svc;


--
-- Name: TABLE platform_notifications; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_notifications TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_notifications TO mathprep_platform_local;


--
-- Name: COLUMN platform_notifications.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id),INSERT(id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(tenant_id),INSERT(tenant_id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.recipient_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(recipient_principal_id),INSERT(recipient_principal_id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.kind; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(kind),INSERT(kind) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.reference_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(reference_id),INSERT(reference_id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.class_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(class_id),INSERT(class_id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.created_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(created_at) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.read_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(read_at),UPDATE(read_at) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: COLUMN platform_notifications.session_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(session_id),INSERT(session_id) ON TABLE mathprep.platform_notifications TO platform_api_svc;


--
-- Name: TABLE platform_password_recovery_intent; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_password_recovery_intent TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_password_recovery_intent.intent_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(intent_id) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(principal_id) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.phone_identity_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(phone_identity_id) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.device_binding; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_binding) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: COLUMN platform_password_recovery_intent.completed_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(completed_at) ON TABLE mathprep.platform_password_recovery_intent TO platform_api_svc;


--
-- Name: TABLE platform_placements; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_placements TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_placements TO mathprep_platform_local;


--
-- Name: COLUMN platform_placements.child_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(child_id) ON TABLE mathprep.platform_placements TO platform_api_svc;


--
-- Name: COLUMN platform_placements.class_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(class_id) ON TABLE mathprep.platform_placements TO platform_api_svc;


--
-- Name: COLUMN platform_placements.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(status) ON TABLE mathprep.platform_placements TO platform_api_svc;


--
-- Name: TABLE platform_push_outbox; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.notification_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(notification_id) ON TABLE mathprep.platform_push_outbox TO platform_api_svc;


--
-- Name: COLUMN platform_push_outbox.recipient_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(recipient_principal_id) ON TABLE mathprep.platform_push_outbox TO platform_api_svc;


--
-- Name: COLUMN platform_push_outbox.event_kind; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(event_kind) ON TABLE mathprep.platform_push_outbox TO platform_api_svc;


--
-- Name: COLUMN platform_push_outbox.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.attempt_count; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(attempt_count) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.next_attempt_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(next_attempt_at) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.lease_token; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(lease_token) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.lease_expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(lease_expires_at) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.delivered_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(delivered_at) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.last_error_class; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(last_error_class) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_outbox.updated_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(updated_at) ON TABLE mathprep.platform_push_outbox TO mathprep_notifications_svc;


--
-- Name: TABLE platform_push_preferences; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE ON TABLE mathprep.platform_push_preferences TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_preferences.quiet_start; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(quiet_start) ON TABLE mathprep.platform_push_preferences TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_preferences.quiet_end; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(quiet_end) ON TABLE mathprep.platform_push_preferences TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_preferences.time_zone; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(time_zone) ON TABLE mathprep.platform_push_preferences TO mathprep_notifications_svc;


--
-- Name: COLUMN platform_push_preferences.updated_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(updated_at) ON TABLE mathprep.platform_push_preferences TO mathprep_notifications_svc;


--
-- Name: TABLE platform_push_subscriptions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_push_subscriptions TO mathprep_notifications_svc;


--
-- Name: TABLE platform_registration_intent; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_registration_intent TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_registration_intent TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_registration_intent.intent_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(intent_id) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.email; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(email),UPDATE(email) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.password_hash; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(password_hash),UPDATE(password_hash) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.display_name; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(display_name),UPDATE(display_name) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.locale; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(locale) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.requested_role; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(requested_role) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.phone_e164; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(phone_e164),UPDATE(phone_e164) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.terms_version; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(terms_version) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.terms_acknowledged_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(terms_acknowledged_at) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.device_binding; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_binding),UPDATE(device_binding) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.finalized_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(finalized_principal_id) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: COLUMN platform_registration_intent.finalized_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(finalized_at) ON TABLE mathprep.platform_registration_intent TO platform_api_svc;


--
-- Name: TABLE platform_schools; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_schools TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_schools TO mathprep_platform_local;


--
-- Name: COLUMN platform_schools.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_schools TO platform_api_svc;


--
-- Name: COLUMN platform_schools.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(tenant_id) ON TABLE mathprep.platform_schools TO platform_api_svc;


--
-- Name: TABLE platform_sessions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_sessions TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_sessions TO mathprep_platform_local;
GRANT SELECT ON TABLE mathprep.platform_sessions TO mathprep_notifications_svc;


--
-- Name: TABLE platform_staff_requests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_staff_requests TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_staff_requests TO mathprep_platform_local;


--
-- Name: TABLE platform_student_access_intent; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_student_access_intent TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_student_access_intent.intent_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(intent_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(tenant_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.child_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(child_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.child_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(child_principal_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.guardian_relationship_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(guardian_relationship_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.guardian_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(guardian_principal_id) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.email; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(email),UPDATE(email) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.password_hash; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(password_hash),UPDATE(password_hash) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.phone_e164; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(phone_e164),UPDATE(phone_e164) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.device_binding; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_binding),UPDATE(device_binding) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_access_intent.finalized_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(finalized_at) ON TABLE mathprep.platform_student_access_intent TO platform_api_svc;


--
-- Name: TABLE platform_student_phone_enrollment_intent; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.intent_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(intent_id) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(principal_id) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.membership_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(membership_id) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.device_binding; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(device_binding),UPDATE(device_binding) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(status) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: COLUMN platform_student_phone_enrollment_intent.completed_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(completed_at) ON TABLE mathprep.platform_student_phone_enrollment_intent TO platform_api_svc;


--
-- Name: TABLE platform_student_profile_link; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT SELECT ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.link_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(link_id) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(link_id) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.student_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(student_principal_id) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(student_principal_id) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.student_tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(student_tenant_id) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(student_tenant_id) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.family_tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(family_tenant_id) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE(family_tenant_id) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.child_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(child_id) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE(child_id) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.pairing_code_digest; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(pairing_code_digest),UPDATE(pairing_code_digest) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(pairing_code_digest),UPDATE(pairing_code_digest) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.status; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(status),UPDATE(status) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(status),UPDATE(status) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT INSERT(expires_at) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.family_confirmed_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(family_confirmed_at) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE(family_confirmed_at) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.student_confirmed_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(student_confirmed_at) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE(student_confirmed_at) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_profile_link.closed_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(closed_at) ON TABLE mathprep.platform_student_profile_link TO platform_api_svc;
GRANT UPDATE(closed_at) ON TABLE mathprep.platform_student_profile_link TO mathprep_platform_local;


--
-- Name: TABLE platform_student_self_profile; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT SELECT ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.profile_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(profile_id) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(profile_id) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.student_principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(student_principal_id) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(student_principal_id) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.student_tenant_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(student_tenant_id) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(student_tenant_id) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.engine_student_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(engine_student_id) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(engine_student_id) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.name; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(name) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(name) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.grade; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(grade) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(grade) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.locale; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(locale) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(locale) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: COLUMN platform_student_self_profile.preview_notice_version; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(preview_notice_version) ON TABLE mathprep.platform_student_self_profile TO platform_api_svc;
GRANT INSERT(preview_notice_version) ON TABLE mathprep.platform_student_self_profile TO mathprep_platform_local;


--
-- Name: TABLE platform_teacher_classes; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_teacher_classes TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_teacher_classes TO mathprep_platform_local;


--
-- Name: COLUMN platform_teacher_classes.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(principal_id) ON TABLE mathprep.platform_teacher_classes TO platform_api_svc;


--
-- Name: COLUMN platform_teacher_classes.class_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(class_id) ON TABLE mathprep.platform_teacher_classes TO platform_api_svc;


--
-- Name: TABLE platform_tests; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.platform_tests TO mathprep_app;
GRANT SELECT,INSERT,UPDATE ON TABLE mathprep.platform_tests TO mathprep_platform_local;


--
-- Name: COLUMN platform_tests.id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(id) ON TABLE mathprep.platform_tests TO platform_api_svc;


--
-- Name: COLUMN platform_tests.class_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(class_id) ON TABLE mathprep.platform_tests TO platform_api_svc;


--
-- Name: COLUMN platform_tests.kind; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(kind),INSERT(kind) ON TABLE mathprep.platform_tests TO platform_api_svc;


--
-- Name: COLUMN platform_tests.due_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT(due_at),INSERT(due_at) ON TABLE mathprep.platform_tests TO platform_api_svc;


--
-- Name: TABLE platform_trusted_device; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT ON TABLE mathprep.platform_trusted_device TO platform_api_svc;
GRANT SELECT,DELETE ON TABLE mathprep.platform_trusted_device TO platform_auth_retention_svc;


--
-- Name: COLUMN platform_trusted_device.trusted_device_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(trusted_device_id) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: COLUMN platform_trusted_device.principal_id; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(principal_id) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: COLUMN platform_trusted_device.token_digest; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(token_digest) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: COLUMN platform_trusted_device.last_seen_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(last_seen_at) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: COLUMN platform_trusted_device.expires_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT INSERT(expires_at),UPDATE(expires_at) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: COLUMN platform_trusted_device.revoked_at; Type: ACL; Schema: mathprep; Owner: -
--

GRANT UPDATE(revoked_at) ON TABLE mathprep.platform_trusted_device TO platform_api_svc;


--
-- Name: TABLE profile_level_history; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.profile_level_history TO mathprep_app;


--
-- Name: TABLE profile_pauses; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.profile_pauses TO mathprep_app;


--
-- Name: TABLE profile_schedules; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.profile_schedules TO mathprep_app;


--
-- Name: TABLE restore_drills; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.restore_drills TO mathprep_app;


--
-- Name: TABLE retake_authorizations; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.retake_authorizations TO mathprep_app;


--
-- Name: TABLE retention_runs; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.retention_runs TO mathprep_app;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.schema_migrations TO mathprep_app;
GRANT SELECT ON TABLE mathprep.schema_migrations TO mathprep_platform_local;


--
-- Name: TABLE skill_event_exclusions; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.skill_event_exclusions TO mathprep_app;


--
-- Name: TABLE skill_events; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.skill_events TO mathprep_app;


--
-- Name: TABLE skill_prerequisites; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.skill_prerequisites TO mathprep_app;


--
-- Name: TABLE skills; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.skills TO mathprep_app;


--
-- Name: TABLE slo_daily_aggregates; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.slo_daily_aggregates TO mathprep_app;


--
-- Name: TABLE telegram_delivery_attempts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.telegram_delivery_attempts TO mathprep_app;


--
-- Name: TABLE telegram_update_receipts; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.telegram_update_receipts TO mathprep_app;


--
-- Name: TABLE topics; Type: ACL; Schema: mathprep; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE mathprep.topics TO mathprep_app;


--
-- Name: TABLE billing_order; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.billing_order TO platform_api_svc;


--
-- Name: COLUMN billing_order.status; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(status) ON TABLE public.billing_order TO platform_api_svc;


--
-- Name: COLUMN billing_order.updated_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(updated_at) ON TABLE public.billing_order TO platform_api_svc;


--
-- Name: COLUMN billing_order.paid_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(paid_at) ON TABLE public.billing_order TO platform_api_svc;


--
-- Name: TABLE billing_order_child; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.billing_order_child TO platform_api_svc;


--
-- Name: TABLE cas_evaluation_request; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.cas_evaluation_request TO cas_svc;
GRANT SELECT,INSERT ON TABLE public.cas_evaluation_request TO grader_svc;


--
-- Name: COLUMN cas_evaluation_request.status; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(status) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.verdict; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(verdict) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.reason_code; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(reason_code) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.result_json; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(result_json) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.started_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(started_at) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.completed_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(completed_at) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.lease_expires_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(lease_expires_at) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.heartbeat_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(heartbeat_at) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: COLUMN cas_evaluation_request.attempt_count; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(attempt_count) ON TABLE public.cas_evaluation_request TO cas_svc;


--
-- Name: TABLE cas_evaluation_status; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.cas_evaluation_status TO cas_svc;


--
-- Name: TABLE cas_operation_type; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.cas_operation_type TO cas_svc;


--
-- Name: TABLE cas_submission; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.cas_submission TO grader_svc;


--
-- Name: TABLE child_entitlement_period; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.child_entitlement_period TO platform_api_svc;


--
-- Name: TABLE event_log; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT ON TABLE public.event_log TO cas_svc;
GRANT INSERT ON TABLE public.event_log TO taskgen_svc;
GRANT INSERT ON TABLE public.event_log TO grader_svc;


--
-- Name: TABLE generation_request; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.generation_request TO taskgen_svc;


--
-- Name: TABLE mastery_topic; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.mastery_topic TO grader_svc;


--
-- Name: COLUMN mastery_topic.student_id; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(student_id) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(student_id) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: COLUMN mastery_topic.domain; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(domain) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(domain) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: COLUMN mastery_topic.tier; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(tier) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(tier) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: COLUMN mastery_topic.ema_score; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(ema_score) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(ema_score) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: COLUMN mastery_topic.updated_at; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(updated_at) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(updated_at) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: COLUMN mastery_topic.evidence_count; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(evidence_count) ON TABLE public.mastery_topic TO platform_api_svc;
GRANT SELECT(evidence_count) ON TABLE public.mastery_topic TO mathprep_platform_local;


--
-- Name: TABLE payment_attempt; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.provider_invoice_id; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(provider_invoice_id) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.provider_payment_id; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(provider_payment_id) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.status; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(status) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.callback_secret_hash_sha256; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(callback_secret_hash_sha256) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.updated_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(updated_at) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: COLUMN payment_attempt.completed_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(completed_at) ON TABLE public.payment_attempt TO platform_api_svc;


--
-- Name: TABLE reason_code; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.reason_code TO cas_svc;


--
-- Name: TABLE students; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.students TO taskgen_svc;


--
-- Name: COLUMN students.user_id; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(user_id),INSERT(user_id) ON TABLE public.students TO platform_api_svc;


--
-- Name: COLUMN students.grade; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT(grade),INSERT(grade),UPDATE(grade) ON TABLE public.students TO platform_api_svc;


--
-- Name: TABLE submission; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.submission TO grader_svc;


--
-- Name: TABLE task_instance; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.task_instance TO taskgen_svc;
GRANT SELECT ON TABLE public.task_instance TO grader_svc;


--
-- Name: TABLE task_set; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.task_set TO taskgen_svc;
GRANT SELECT ON TABLE public.task_set TO grader_svc;


--
-- Name: TABLE task_type; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT,UPDATE ON TABLE public.task_type TO taskgen_svc;
GRANT SELECT ON TABLE public.task_type TO grader_svc;


--
-- Name: TABLE task_type_template; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.task_type_template TO taskgen_svc;


--
-- Name: COLUMN users.user_id; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(user_id) ON TABLE public.users TO platform_api_svc;


--
-- Name: COLUMN users.user_type; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT(user_type) ON TABLE public.users TO platform_api_svc;


--
-- Name: TABLE verdict; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT ON TABLE public.verdict TO cas_svc;


--
-- Name: TABLE verified_provider_event; Type: ACL; Schema: public; Owner: -
--

GRANT SELECT,INSERT ON TABLE public.verified_provider_event TO platform_api_svc;


--
-- Name: COLUMN verified_provider_event.status; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(status) ON TABLE public.verified_provider_event TO platform_api_svc;


--
-- Name: COLUMN verified_provider_event.processed_at; Type: ACL; Schema: public; Owner: -
--

GRANT UPDATE(processed_at) ON TABLE public.verified_provider_event TO platform_api_svc;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: mathprep; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE mathprep_owner IN SCHEMA mathprep GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO mathprep_app;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public GRANT ALL ON SEQUENCES TO taskgen_svc;
ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public GRANT ALL ON SEQUENCES TO grader_svc;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO taskgen_svc;
ALTER DEFAULT PRIVILEGES FOR ROLE mathprep IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO grader_svc;


--
-- PostgreSQL database dump complete
--

\unrestrict dR7cXfcHMyZjWVGHf10gqHuW574khhxqdOo2PNksZ98KjcLbEyQOnaodgRQsn1q

