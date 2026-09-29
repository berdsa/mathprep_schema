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
		"c.confrelid='mathprep.platform_join_requests'::regclass",
		"ARRAY['reference_id']::text[]",
		"c.confrelid='mathprep.platform_classes'::regclass",
		"ARRAY['class_id']::text[]",
		"UNIQUE (recipient_principal_id, tenant_id, kind, reference_id)",
		"c.confrelid='mathprep.platform_tests'::regclass",
		"ARRAY['test_id']::text[]",
		"ARRAY['notification_id','recipient_principal_id','event_kind']::text[]",
		"ARRAY['id','recipient_principal_id','kind']::text[]",
		"array_agg(a.attname::text ORDER BY k.ordinality)",
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
	if upSum != "df82d702e5373bf2da138febd4bae2221f8b137a48d2a8d9d63acfd6eeb506d9" {
		t.Errorf("up checksum changed: %s", upSum)
	}
	if downSum != "689ef073561e7bb8824ec12ce79bab656ef3ab08b418d1b3e0a8174f5d527f58" {
		t.Errorf("down checksum changed: %s", downSum)
	}
}
