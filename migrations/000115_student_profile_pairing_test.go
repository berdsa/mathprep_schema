package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestStudentProfilePairingMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000115_student_profile_pairing.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000115_student_profile_pairing.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	for _, want := range []string{
		"CREATE TABLE mathprep.platform_student_profile_link",
		"student_principal_id UUID NOT NULL REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT",
		"student_tenant_id UUID NOT NULL REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT",
		"family_tenant_id UUID REFERENCES mathprep.access_tenants(id) ON DELETE RESTRICT",
		"child_id UUID REFERENCES mathprep.platform_children(id) ON DELETE RESTRICT",
		"pairing_code_digest TEXT CHECK (pairing_code_digest IS NULL OR pairing_code_digest ~ '^[a-f0-9]{64}$')",
		"status IN ('pending_family', 'pending_student', 'active', 'rejected', 'revoked', 'expired')",
		"expires_at <= created_at + interval '15 minutes'",
		"CREATE UNIQUE INDEX platform_student_profile_link_student_open_idx",
		"CREATE UNIQUE INDEX platform_student_profile_link_child_open_idx",
		"student_kind IS DISTINCT FROM 'student'",
		"family_kind IS DISTINCT FROM 'family'",
		"ac.state='granted' AND ac.purpose='learning'",
		"CREATE TRIGGER platform_student_profile_link_lifecycle_guard",
		"OLD.status='pending_family' AND NEW.status IN ('pending_student','revoked','expired')",
		"OLD.status='pending_student' AND NEW.status IN ('active','rejected','revoked','expired')",
		"OLD.status='active' AND NEW.status='revoked'",
		"GRANT SELECT ON mathprep.platform_student_profile_link TO platform_api_svc",
		"GRANT INSERT (link_id,student_principal_id,student_tenant_id,pairing_code_digest,status,expires_at)",
		"GRANT UPDATE (family_tenant_id,child_id,pairing_code_digest,status,family_confirmed_at,student_confirmed_at,closed_at)",
		"GRANT SELECT ON mathprep.platform_student_profile_link TO mathprep_platform_local",
	} {
		if !strings.Contains(up, want) {
			t.Errorf("up migration missing contract %q", want)
		}
	}
	for _, forbidden := range []string{"pairing_code TEXT", "phone_e164", "consent_id", "GRANT DELETE", "GRANT ALL", "CREATE ROLE"} {
		if strings.Contains(strings.ToLower(up), strings.ToLower(forbidden)) {
			t.Errorf("up migration contains forbidden contract %q", forbidden)
		}
	}
	for _, want := range []string{
		"refusing to roll back 000115: student profile link history exists",
		"REVOKE SELECT ON mathprep.platform_student_profile_link FROM platform_api_svc",
		"DROP TABLE mathprep.platform_student_profile_link",
	} {
		if !strings.Contains(down, want) {
			t.Errorf("down migration missing rollback contract %q", want)
		}
	}
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "a30513a4f7514791a7b822499bfbdd02d45a5a67cd3e8626083fbaea52b972e9" {
		t.Errorf("up migration checksum changed: %s", upSum)
	}
	if downSum != "96c52ffc0c24ad28b3ed20e8b0cece4d7f525cbbfc86316240e079dbf8cb211a" {
		t.Errorf("down migration checksum changed: %s", downSum)
	}
}
