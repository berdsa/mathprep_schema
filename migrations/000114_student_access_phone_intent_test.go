package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestStudentAccessPhoneIntentMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000114_student_access_phone_intent.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000114_student_access_phone_intent.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	for _, want := range []string{
		"CREATE TABLE mathprep.platform_student_access_intent",
		"tenant_id UUID NOT NULL REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT",
		"child_id UUID NOT NULL REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT",
		"child_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT",
		"guardian_relationship_id UUID NOT NULL REFERENCES mathprep.access_guardian_relationships(id) ON DELETE RESTRICT",
		"guardian_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT",
		"phone_e164 TEXT CHECK (phone_e164 IS NULL OR phone_e164 ~ '^\\+[1-9][0-9]{1,14}$')",
		"device_binding TEXT CHECK (device_binding IS NULL OR device_binding ~ '^[a-f0-9]{64}$')",
		"expires_at <= created_at + interval '15 minutes'",
		"status IN ('pending', 'finalized', 'expired')",
		"CREATE UNIQUE INDEX platform_student_access_one_pending_child_idx",
		"CREATE TRIGGER platform_student_access_scope_guard",
		"relationship_guardian IS DISTINCT FROM NEW.guardian_principal_id",
		"tenant_kind IS DISTINCT FROM 'family'",
		"CREATE TRIGGER platform_student_access_lifecycle_guard",
		"NEW.status NOT IN ('finalized', 'expired')",
		"GRANT INSERT ( intent_id, tenant_id, child_id, child_principal_id, guardian_relationship_id, guardian_principal_id, email, password_hash, phone_e164, device_binding, expires_at ) ON mathprep.platform_student_access_intent TO platform_api_svc",
		"GRANT UPDATE (status, finalized_at, email, password_hash, phone_e164, device_binding)",
		"GRANT UPDATE (email) ON mathprep.platform_accounts TO platform_api_svc",
		"CREATE FUNCTION mathprep.prune_platform_student_access_intents(batch_size integer)",
		"batch_size > 500",
		"interval '24 hours'",
		"GRANT EXECUTE ON FUNCTION mathprep.prune_platform_student_access_intents(integer) TO platform_api_svc",
	} {
		if !strings.Contains(up, want) {
			t.Errorf("up migration missing contract %q", want)
		}
	}
	for _, forbidden := range []string{"otp TEXT", "consent_id", "GRANT DELETE ON mathprep.platform_student_access_intent TO platform_api_svc", "GRANT ALL", "CREATE ROLE"} {
		if strings.Contains(strings.ToLower(up), strings.ToLower(forbidden)) {
			t.Errorf("up migration contains forbidden contract %q", forbidden)
		}
	}
	for _, want := range []string{
		"refusing to roll back 000114: student access intent rows exist",
		"REVOKE UPDATE (email) ON mathprep.platform_accounts FROM platform_api_svc",
		"DROP TABLE mathprep.platform_student_access_intent",
	} {
		if !strings.Contains(down, want) {
			t.Errorf("down migration missing rollback contract %q", want)
		}
	}

	// Pin the reviewed SQL bytes. Update these only alongside the agent log and
	// rollout checksum after an intentional migration change.
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "6fcd46cb51856dc05ef4efd8d0d76dcf49a5fa4d8f593f7f4f0378396a3cee91" {
		t.Errorf("up migration checksum changed: %s", upSum)
	}
	if downSum != "021f1d96a394330b9b8bf72078ba40fce36502126b4168ec463d474f0670406d" {
		t.Errorf("down migration checksum changed: %s", downSum)
	}
}
