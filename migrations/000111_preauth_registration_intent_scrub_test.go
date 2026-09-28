package migrations

import (
	"os"
	"strings"
	"testing"
)

func TestFinalizedRegistrationIntentScrubGrantIsScopedAndReversible(t *testing.T) {
	read := func(name string) string {
		t.Helper()
		data, err := os.ReadFile(name)
		if err != nil {
			t.Fatalf("read %s: %v", name, err)
		}
		return strings.Join(strings.Fields(string(data)), " ")
	}
	up := read("000111_preauth_registration_intent_scrub.up.sql")
	down := read("000111_preauth_registration_intent_scrub.down.sql")
	grant := "GRANT UPDATE (email, password_hash, display_name, phone_e164, device_binding) ON mathprep.platform_registration_intent TO platform_api_svc"
	revoke := "REVOKE UPDATE (email, password_hash, display_name, phone_e164, device_binding) ON mathprep.platform_registration_intent FROM platform_api_svc"
	if !strings.Contains(up, grant) {
		t.Fatal("migration must grant only the intent fields that are scrubbed after finalization")
	}
	if !strings.Contains(down, revoke) {
		t.Fatal("down migration must revoke the exact intent columns")
	}
	for _, forbidden := range []string{"GRANT UPDATE ON", "DELETE ON", "GRANT SELECT"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("migration contains broader privilege %q", forbidden)
		}
	}
}
