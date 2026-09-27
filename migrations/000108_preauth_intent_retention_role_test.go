package migrations

import (
	"os"
	"strings"
	"testing"
)

func retentionRoleMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestPreauthRetentionRoleIsExplicitAndNarrow(t *testing.T) {
	up := retentionRoleMigrationSQL(t, "000108_preauth_intent_retention_role.up.sql")
	down := retentionRoleMigrationSQL(t, "000108_preauth_intent_retention_role.down.sql")
	for _, want := range []string{
		"CREATE ROLE platform_auth_retention_svc NOLOGIN",
		"GRANT DELETE ON mathprep.platform_registration_intent, mathprep.platform_login_intent, mathprep.platform_trusted_device TO platform_auth_retention_svc",
		"GRANT platform_auth_retention_svc TO platform_api_svc WITH INHERIT FALSE, SET TRUE",
		"CREATE INDEX platform_registration_intent_retention_idx",
		"CREATE INDEX platform_login_intent_retention_idx",
		"CREATE INDEX platform_trusted_device_retention_idx",
	} {
		if !strings.Contains(up, want) {
			t.Fatalf("up migration missing %q", want)
		}
	}
	if strings.Contains(up, "GRANT DELETE ON ALL") || strings.Contains(up, "TRUNCATE") {
		t.Fatal("retention migration grants broad destructive privileges")
	}
	for _, want := range []string{"REVOKE platform_auth_retention_svc FROM platform_api_svc", "DROP ROLE platform_auth_retention_svc"} {
		if !strings.Contains(down, want) {
			t.Fatalf("down migration missing %q", want)
		}
	}
}
