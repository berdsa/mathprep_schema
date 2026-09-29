package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestPlatformNotificationAPIGrantsMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000124_platform_notification_api_grants.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000124_platform_notification_api_grants.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")

	for _, required := range []string{
		"rolname='platform_api_svc'",
		"000124 requires platform notification, learning-session, and push-outbox relations",
		"required inbox or recipient-scope columns are missing",
		"000124 requires the existing 000102 outbox identity INSERT grants",
		"has_column_privilege('platform_api_svc','mathprep.platform_push_outbox','notification_id','INSERT')",
		"GRANT SELECT ( id, kind, reference_id, session_id, class_id, created_at, read_at, recipient_principal_id, tenant_id ) ON mathprep.platform_notifications TO platform_api_svc",
		"GRANT INSERT ( id, tenant_id, recipient_principal_id, kind, reference_id, class_id, session_id ) ON mathprep.platform_notifications TO platform_api_svc",
		"GRANT UPDATE (read_at) ON mathprep.platform_notifications TO platform_api_svc",
		"GRANT SELECT (id, test_id, child_id, mode, status, finished_at) ON mathprep.platform_learning_sessions TO platform_api_svc",
		"GRANT SELECT (id, class_id) ON mathprep.platform_tests TO platform_api_svc",
		"GRANT SELECT (id, school_id) ON mathprep.platform_classes TO platform_api_svc",
		"GRANT SELECT (id, tenant_id) ON mathprep.platform_schools TO platform_api_svc",
		"GRANT SELECT (id, status) ON mathprep.access_tenants TO platform_api_svc",
		"GRANT SELECT (id, tenant_id, status, principal_id, learner_id) ON mathprep.platform_children TO platform_api_svc",
		"GRANT SELECT (child_id, class_id, status) ON mathprep.platform_placements TO platform_api_svc",
		"GRANT SELECT (tenant_id, principal_id, status, role) ON mathprep.access_memberships TO platform_api_svc",
		"GRANT SELECT (id, status) ON mathprep.access_principals TO platform_api_svc",
		"GRANT SELECT (class_id, principal_id) ON mathprep.platform_teacher_classes TO platform_api_svc",
		"GRANT SELECT (id, class_id, child_id) ON mathprep.platform_join_requests TO platform_api_svc",
		"GRANT SELECT (learner_id, tenant_id, guardian_principal_id, state) ON mathprep.access_guardian_relationships TO platform_api_svc",
	} {
		if !strings.Contains(up, required) {
			t.Errorf("up migration is missing contract %q", required)
		}
	}
	if strings.Contains(up, "GRANT SELECT ON ") || strings.Contains(up, "GRANT INSERT ON ") || strings.Contains(up, "GRANT UPDATE ON ") || strings.Contains(up, "GRANT ALL") {
		t.Error("migration must use column-scoped grants only")
	}
	if strings.Contains(up, "GRANT ") && strings.Contains(up, "mathprep.platform_push_outbox TO platform_api_svc") {
		t.Error("000124 must leave the existing 000102 outbox grant unchanged")
	}
	for _, required := range []string{
		"REVOKE SELECT ( id, kind, reference_id, session_id, class_id, created_at, read_at, recipient_principal_id, tenant_id ) ON mathprep.platform_notifications FROM platform_api_svc",
		"REVOKE INSERT ( id, tenant_id, recipient_principal_id, kind, reference_id, class_id, session_id ) ON mathprep.platform_notifications FROM platform_api_svc",
		"REVOKE UPDATE (read_at) ON mathprep.platform_notifications FROM platform_api_svc",
		"REVOKE SELECT (id, test_id, child_id, mode, status, finished_at) ON mathprep.platform_learning_sessions FROM platform_api_svc",
		"REVOKE SELECT (id, class_id) ON mathprep.platform_tests FROM platform_api_svc",
		"REVOKE SELECT (id, school_id) ON mathprep.platform_classes FROM platform_api_svc",
		"REVOKE SELECT (id, tenant_id) ON mathprep.platform_schools FROM platform_api_svc",
		"REVOKE SELECT (id, status) ON mathprep.access_tenants FROM platform_api_svc",
		"REVOKE SELECT (id, tenant_id, status, principal_id, learner_id) ON mathprep.platform_children FROM platform_api_svc",
		"REVOKE SELECT (child_id, class_id, status) ON mathprep.platform_placements FROM platform_api_svc",
		"REVOKE SELECT (tenant_id, principal_id, status, role) ON mathprep.access_memberships FROM platform_api_svc",
		"REVOKE SELECT (id, status) ON mathprep.access_principals FROM platform_api_svc",
		"REVOKE SELECT (class_id, principal_id) ON mathprep.platform_teacher_classes FROM platform_api_svc",
		"REVOKE SELECT (id, class_id, child_id) ON mathprep.platform_join_requests FROM platform_api_svc",
		"REVOKE SELECT (learner_id, tenant_id, guardian_principal_id, state) ON mathprep.access_guardian_relationships FROM platform_api_svc",
	} {
		if !strings.Contains(down, required) {
			t.Errorf("down migration is missing exact revoke %q", required)
		}
	}

	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "9001fa09c1f50765a2759d0f5d40d7c3caeab7a445786b57c5905e0790b22f99" {
		t.Errorf("up checksum changed: %s", upSum)
	}
	if downSum != "eff7eb58488416409cbadd267c3f9ce5bb3fa712900e95aebdf3e5e3d323febe" {
		t.Errorf("down checksum changed: %s", downSum)
	}
}
