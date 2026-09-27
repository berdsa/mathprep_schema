package migrations

import (
	"os"
	"strings"
	"testing"
)

func retentionFunctionMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestPreauthRetentionFunctionIsBoundedAndNotPublic(t *testing.T) {
	up := retentionFunctionMigrationSQL(t, "000109_preauth_retention_function.up.sql")
	down := retentionFunctionMigrationSQL(t, "000109_preauth_retention_function.down.sql")
	for _, want := range []string{
		"REVOKE platform_auth_retention_svc FROM platform_api_svc",
		"CREATE FUNCTION mathprep.prune_platform_preauth_state(batch_size integer)",
		"SECURITY DEFINER",
		"SET search_path = pg_catalog, mathprep",
		"batch_size > 500",
		"interval '24 hours'",
		"ORDER BY expires_at LIMIT batch_size",
		"REVOKE ALL ON FUNCTION mathprep.prune_platform_preauth_state(integer) FROM PUBLIC",
		"GRANT EXECUTE ON FUNCTION mathprep.prune_platform_preauth_state(integer) TO platform_api_svc",
	} {
		if !strings.Contains(up, want) {
			t.Fatalf("up migration missing %q", want)
		}
	}
	if !strings.Contains(down, "GRANT platform_auth_retention_svc TO platform_api_svc WITH INHERIT FALSE, SET TRUE") {
		t.Fatal("down migration does not restore the 000108 access contract")
	}
}
