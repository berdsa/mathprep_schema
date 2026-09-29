package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestPlatformAssessmentReadyMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000123_platform_assessment_ready.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000123_platform_assessment_ready.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")

	for _, required := range []string{
		"to_regclass('mathprep.platform_notifications') IS NULL",
		"to_regclass('mathprep.platform_learning_sessions') IS NULL",
		"to_regclass('mathprep.platform_push_outbox') IS NULL",
		"baseline platform table columns are incomplete",
		"baseline platform table constraints/indexes do not match the reviewed contract",
		"baseline inbox reference, class, recipient, and tenant UUID columns to be NOT NULL",
		"FOREIGN KEY (reference_id) REFERENCES mathprep.platform_join_requests(id)",
		"FOREIGN KEY (class_id) REFERENCES mathprep.platform_classes(id)",
		"UNIQUE (recipient_principal_id, tenant_id, kind, reference_id)",
		"FOREIGN KEY (test_id) REFERENCES mathprep.platform_tests(id)",
		"FOREIGN KEY (notification_id, recipient_principal_id, event_kind) REFERENCES mathprep.platform_notifications(id, recipient_principal_id, kind)",
		"ADD COLUMN session_id UUID",
		"ALTER COLUMN reference_id DROP NOT NULL",
		"REFERENCES mathprep.platform_learning_sessions(id)",
		"kind='assessment_ready' AND reference_id IS NULL AND session_id IS NOT NULL",
		"kind IN ('join_requested','join_approved','join_declined') AND reference_id IS NOT NULL AND session_id IS NULL",
		"CREATE UNIQUE INDEX platform_notifications_assessment_ready_session_uq",
		"WHERE kind='assessment_ready'",
		"event_kind IN ('join_requested','join_approved','join_declined','assessment_ready')",
		"GRANT INSERT (session_id) ON mathprep.platform_notifications TO platform_api_svc",
	} {
		if !strings.Contains(up, required) {
			t.Errorf("up migration is missing contract %q", required)
		}
	}
	if strings.Contains(up, "DROP TABLE") || strings.Contains(up, "DROP SCHEMA") || strings.Contains(up, "CASCADE") {
		t.Error("up migration must remain additive and may not use destructive DDL")
	}
	for _, required := range []string{
		"WHERE kind='assessment_ready' OR session_id IS NOT NULL",
		"WHERE event_kind='assessment_ready'",
		"cannot roll back assessment_ready while assessment inbox or outbox rows exist",
		"REVOKE INSERT (session_id) ON mathprep.platform_notifications FROM platform_api_svc",
		"DROP COLUMN session_id",
		"ALTER COLUMN reference_id SET NOT NULL",
		"event_kind IN ('join_requested','join_approved','join_declined')",
		"kind IN ('join_requested','join_approved','join_declined')",
	} {
		if !strings.Contains(down, required) {
			t.Errorf("down migration is missing rollback contract %q", required)
		}
	}
	if strings.Contains(up, "GRANT SELECT") || strings.Contains(up, "GRANT UPDATE") || strings.Contains(up, "GRANT DELETE") {
		t.Error("migration must grant only the new inbox INSERT column")
	}

	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "ad58945cc1e2a546c1fe441f703058352ce596a57c48e8c76dbdab79dd662afa" {
		t.Errorf("up checksum changed: %s", upSum)
	}
	if downSum != "689ef073561e7bb8824ec12ce79bab656ef3ab08b418d1b3e0a8174f5d527f58" {
		t.Errorf("down checksum changed: %s", downSum)
	}
}
