package migrations

import (
	"os"
	"strings"
	"testing"
)

func TestStudentPhoneEnrollmentMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000118_student_phone_enrollment.up.sql")
	if err != nil { t.Fatal(err) }
	downBytes, err := os.ReadFile("000118_student_phone_enrollment.down.sql")
	if err != nil { t.Fatal(err) }
	up, down := string(upBytes), string(downBytes)
	for _, want := range []string{
		"CREATE TABLE mathprep.platform_student_phone_enrollment_intent",
		"membership_id UUID NOT NULL REFERENCES mathprep.access_memberships(id)",
		"device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$')",
		"expires_at <= created_at + interval '10 minutes'",
		"m.role = 'student'",
		"m.status = 'active'",
		"NEW.device_binding IS NOT NULL",
		"GRANT UPDATE (status, completed_at, device_binding)",
		"interval '24 hours'",
		"GRANT EXECUTE ON FUNCTION mathprep.prune_platform_student_phone_enrollment_intents(integer)",
	} {
		if !strings.Contains(up, want) { t.Errorf("up migration missing %q", want) }
	}
	for _, forbidden := range []string{"phone_e164 TEXT", "otp TEXT", "password_hash TEXT", "guardian_principal_id", "consent_id", "GRANT ALL", "GRANT DELETE ON mathprep.platform_student_phone_enrollment_intent TO platform_api_svc"} {
		if strings.Contains(strings.ToLower(up), strings.ToLower(forbidden)) { t.Errorf("up migration contains forbidden construct %q", forbidden) }
	}
	for _, want := range []string{"refusing to roll back 000118 while student phone enrollment intent rows exist", "DROP TABLE mathprep.platform_student_phone_enrollment_intent"} {
		if !strings.Contains(down, want) { t.Errorf("down migration missing %q", want) }
	}
}
