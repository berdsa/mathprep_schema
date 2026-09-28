package migrations

import (
	"os"
	"strings"
	"testing"
)

func TestPlatformPasswordRecoveryIntentMigrationContract(t *testing.T) {
	up, err := os.ReadFile("000113_platform_password_recovery_intents.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	down, err := os.ReadFile("000113_platform_password_recovery_intents.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	upSQL, downSQL := string(up), string(down)
	for _, required := range []string{
		"CREATE TABLE mathprep.platform_password_recovery_intent",
		"REFERENCES mathprep.access_principals(id)",
		"REFERENCES mathprep.phone_identity(phone_identity_id)",
		"device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$')",
		"CHECK (expires_at > created_at)",
		"status IN ('pending', 'completed', 'expired')",
		"CREATE UNIQUE INDEX platform_password_recovery_one_pending_principal_idx",
		"GRANT INSERT (\n    intent_id, principal_id, phone_identity_id, device_binding, expires_at\n) ON mathprep.platform_password_recovery_intent TO platform_api_svc",
		"GRANT UPDATE (status, completed_at)",
		"GRANT UPDATE (password_hash) ON mathprep.platform_accounts TO platform_api_svc",
		"GRANT SELECT, DELETE ON mathprep.platform_password_recovery_intent\n    TO platform_auth_retention_svc",
		"CREATE OR REPLACE FUNCTION mathprep.prune_platform_preauth_state(batch_size integer)",
	} {
		if !strings.Contains(upSQL, required) {
			t.Errorf("up migration missing contract %q", required)
		}
	}
	for _, forbidden := range []string{"phone_e164 TEXT", "email TEXT", "password_hash TEXT", "otp TEXT", "GRANT DELETE ON mathprep.platform_password_recovery_intent TO platform_api_svc", "GRANT UPDATE ON mathprep.platform_accounts"} {
		if strings.Contains(upSQL, forbidden) {
			t.Errorf("up migration contains forbidden contract %q", forbidden)
		}
	}
	for _, required := range []string{
		"refusing to roll back 000113: password recovery intent rows exist",
		"REVOKE UPDATE (password_hash) ON mathprep.platform_accounts FROM platform_api_svc",
		"DROP TABLE mathprep.platform_password_recovery_intent",
	} {
		if !strings.Contains(downSQL, required) {
			t.Errorf("down migration missing rollback guard %q", required)
		}
	}
}
