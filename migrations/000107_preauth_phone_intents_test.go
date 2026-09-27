package migrations

import (
	"os"
	"strings"
	"testing"
)

func preauthIntentMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestPreauthIntentMigrationDefinesContractAndLeastPrivilege(t *testing.T) {
	up := preauthIntentMigrationSQL(t, "000107_preauth_phone_intents.up.sql")
	down := preauthIntentMigrationSQL(t, "000107_preauth_phone_intents.down.sql")

	for _, want := range []string{
		"CREATE TABLE mathprep.platform_registration_intent",
		"CREATE TABLE mathprep.platform_login_intent",
		"CREATE TABLE mathprep.platform_trusted_device",
		"requested_role IN ('family_owner', 'student')",
		"status IN ('pending', 'finalized', 'expired')",
		"status IN ('pending', 'completed', 'expired')",
		"phone_e164 ~ '^\\+[1-9][0-9]{1,14}$'",
		"device_token_digest ~ '^[0-9a-f]{64}$'",
		"token_digest ~ '^[0-9a-f]{64}$'",
		"device_binding TEXT NOT NULL CHECK (device_binding ~ '^[a-f0-9]{64}$')",
		"REFERENCES mathprep.access_principals(id) ON DELETE RESTRICT",
		"REFERENCES mathprep.access_memberships(id) ON DELETE RESTRICT",
		"REFERENCES mathprep.phone_identity(phone_identity_id) ON DELETE RESTRICT",
		"GRANT UPDATE (status, finalized_principal_id, finalized_at)",
		"GRANT UPDATE (device_token_digest, status)",
		"GRANT UPDATE (last_seen_at, expires_at, revoked_at)",
		"GRANT INSERT (verified_at) ON mathprep.phone_identity TO platform_api_svc",
	} {
		if !strings.Contains(up, want) {
			t.Errorf("up migration is missing required contract capability: %s", want)
		}
	}

	for _, forbidden := range []string{
		"CREATE ROLE",
		"auth_svc",
		"GRANT ALL",
		"GRANT DELETE",
		"GRANT TRUNCATE",
	} {
		if strings.Contains(up, forbidden) {
			t.Errorf("up migration contains forbidden capability: %s", forbidden)
		}
	}

	guard := "IF EXISTS (SELECT 1 FROM mathprep.platform_registration_intent LIMIT 1) OR EXISTS (SELECT 1 FROM mathprep.platform_login_intent LIMIT 1) OR EXISTS (SELECT 1 FROM mathprep.platform_trusted_device LIMIT 1) THEN RAISE EXCEPTION 'refusing to roll back 000107: pre-auth intent/device rows exist'"
	if !strings.Contains(down, guard) {
		t.Error("down migration does not refuse rollback when retained rows exist")
	}
	if !strings.Contains(down, "END; $$;") {
		t.Error("down migration row-preservation guard is not a complete PL/pgSQL block")
	}
	if strings.Index(down, guard) > strings.Index(down, "DROP TABLE") {
		t.Error("down migration drops tables before its row-preservation guard")
	}
	for _, table := range []string{
		"mathprep.platform_trusted_device",
		"mathprep.platform_login_intent",
		"mathprep.platform_registration_intent",
	} {
		if !strings.Contains(down, "DROP TABLE "+table) {
			t.Errorf("down migration does not remove empty table %s", table)
		}
	}
}
