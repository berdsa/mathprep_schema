package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestStudentSelfLearningProfileMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000117_student_self_learning_profile.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000117_student_self_learning_profile.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up, down := string(upBytes), string(downBytes)
	for _, want := range []string{
		"CREATE TABLE mathprep.platform_student_self_profile",
		"UNIQUE (student_principal_id, student_tenant_id)",
		"t.kind='student'",
		"m.role='student'",
		"preview_notice_version = 'student-self-preview-v1'",
		"ALTER COLUMN child_id DROP NOT NULL",
		"self_profile_id UUID REFERENCES mathprep.platform_student_self_profile(profile_id)",
		"platform_learning_sessions_one_owner_check",
		"GRANT INSERT (self_profile_id) ON mathprep.platform_learning_sessions TO platform_api_svc",
		"GRANT INSERT (id,tenant_id,event_type,actor_principal_id,correlation_id,safe_payload)",
	} {
		if !strings.Contains(up, want) {
			t.Errorf("up migration missing %q", want)
		}
	}
	for _, forbidden := range []string{"access_guardian_relationships", "access_consents", "family_owner", "CREATE TABLE mathprep.learners", "GRANT DELETE", "GRANT ALL"} {
		if strings.Contains(strings.ToLower(up), strings.ToLower(forbidden)) {
			t.Errorf("up migration contains forbidden construct %q", forbidden)
		}
	}
	for _, want := range []string{"refusing to roll back 000117: self-owned learning history exists", "DROP COLUMN self_profile_id", "ALTER COLUMN child_id SET NOT NULL"} {
		if !strings.Contains(down, want) {
			t.Errorf("down migration missing %q", want)
		}
	}
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "267f85826d277dbc63cd4b87b80f372cd868ecbcb4e00c3a6913822fda3f8792" {
		t.Errorf("up checksum changed: %s", upSum)
	}
	if downSum != "cea8da4120583ada34178890762b0c4119010ee898c2568eb4ea2f07dcf96ba3" {
		t.Errorf("down checksum changed: %s", downSum)
	}
}
