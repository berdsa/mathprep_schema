package migrations

import (
	"os"
	"strings"
	"testing"
)

func profileSelfUpdateMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestProfileSelfUpdateGrantIsColumnScopedAndReversible(t *testing.T) {
	up := profileSelfUpdateMigrationSQL(t, "000110_platform_profile_self_update.up.sql")
	down := profileSelfUpdateMigrationSQL(t, "000110_platform_profile_self_update.down.sql")
	if !strings.Contains(up, "GRANT UPDATE (name, locale) ON mathprep.platform_accounts TO platform_api_svc") {
		t.Fatal("profile grant must update only name and locale")
	}
	if !strings.Contains(down, "REVOKE UPDATE (name, locale) ON mathprep.platform_accounts FROM platform_api_svc") {
		t.Fatal("down migration does not revoke the exact profile columns")
	}
	for _, forbidden := range []string{"GRANT UPDATE ON", "UPDATE(password_hash", "UPDATE(email", "UPDATE(role"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("profile migration contains broader update grant %q", forbidden)
		}
	}
}
