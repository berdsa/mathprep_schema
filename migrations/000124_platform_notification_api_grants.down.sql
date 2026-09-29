REVOKE SELECT (
    id, kind, reference_id, session_id, class_id, created_at, read_at,
    recipient_principal_id, tenant_id
) ON mathprep.platform_notifications FROM platform_api_svc;
REVOKE INSERT (
    id, tenant_id, recipient_principal_id, kind, reference_id, class_id, session_id
) ON mathprep.platform_notifications FROM platform_api_svc;
REVOKE UPDATE (read_at)
    ON mathprep.platform_notifications FROM platform_api_svc;

REVOKE SELECT (id, test_id, child_id, mode, status, finished_at)
    ON mathprep.platform_learning_sessions FROM platform_api_svc;
REVOKE SELECT (id, class_id)
    ON mathprep.platform_tests FROM platform_api_svc;
REVOKE SELECT (id, school_id)
    ON mathprep.platform_classes FROM platform_api_svc;
REVOKE SELECT (id, tenant_id)
    ON mathprep.platform_schools FROM platform_api_svc;
REVOKE SELECT (id, status)
    ON mathprep.access_tenants FROM platform_api_svc;
REVOKE SELECT (id, tenant_id, status, principal_id, learner_id)
    ON mathprep.platform_children FROM platform_api_svc;
REVOKE SELECT (child_id, class_id, status)
    ON mathprep.platform_placements FROM platform_api_svc;
REVOKE SELECT (tenant_id, principal_id, status, role)
    ON mathprep.access_memberships FROM platform_api_svc;
REVOKE SELECT (id, status)
    ON mathprep.access_principals FROM platform_api_svc;
REVOKE SELECT (class_id, principal_id)
    ON mathprep.platform_teacher_classes FROM platform_api_svc;
REVOKE SELECT (id, class_id, child_id)
    ON mathprep.platform_join_requests FROM platform_api_svc;
REVOKE SELECT (learner_id, tenant_id, guardian_principal_id, state)
    ON mathprep.access_guardian_relationships FROM platform_api_svc;
