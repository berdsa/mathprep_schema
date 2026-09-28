package migrations

import (
	"os"
	"strings"
	"testing"
)

func TestPushQuietHoursMigrationIsPrincipalScoped(t *testing.T) {
	read := func(name string) string {
		t.Helper()
		b, err := os.ReadFile(name)
		if err != nil { t.Fatal(err) }
		return strings.Join(strings.Fields(string(b)), " ")
	}
	up, down := read("000112_platform_push_quiet_hours.up.sql"), read("000112_platform_push_quiet_hours.down.sql")
	for _, want := range []string{
		"principal_id UUID PRIMARY KEY REFERENCES mathprep.access_principals(id) ON DELETE CASCADE",
		"quiet_start IS NULL AND quiet_end IS NULL",
		"quiet_start <> quiet_end",
		"GRANT SELECT, INSERT, DELETE ON mathprep.platform_push_preferences TO mathprep_notifications_svc",
		"GRANT UPDATE (quiet_start, quiet_end, time_zone, updated_at)",
	} { if !strings.Contains(up, want) { t.Errorf("migration missing %q", want) } }
	for _, forbidden := range []string{"GRANT ALL", "TO platform_api_svc", "GRANT UPDATE ON"} {
		if strings.Contains(up, forbidden) { t.Errorf("overbroad grant %q", forbidden) }
	}
	if !strings.Contains(down, "DROP TABLE mathprep.platform_push_preferences") { t.Fatal("down migration missing table drop") }
}
