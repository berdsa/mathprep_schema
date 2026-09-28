package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestNotificationsAccountLocaleLookupMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000121_notifications_account_locale_lookup.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000121_notifications_account_locale_lookup.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	if !strings.Contains(up, "GRANT SELECT (principal_id, locale) ON mathprep.platform_accounts TO mathprep_notifications_svc") {
		t.Fatal("notifications service must read only the principal lookup key and locale")
	}
	if strings.Contains(up, "GRANT SELECT ON mathprep.platform_accounts") || strings.Contains(up, "GRANT ALL") {
		t.Fatal("migration must not grant broad platform-account access")
	}
	if !strings.Contains(down, "REVOKE SELECT (principal_id, locale) ON mathprep.platform_accounts FROM mathprep_notifications_svc") {
		t.Fatal("down migration must revoke only the recipient lookup columns")
	}
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "6590155d538162ecc4ea6e6d87352ff3ae92de08ad9ddc9506a7bb7ea7a2bc79" {
		t.Errorf("up migration checksum changed: %s", upSum)
	}
	if downSum != "50db567c88a69df193f9eb878a52817384c5c9753d262e3eb21c0351dd9d72b1" {
		t.Errorf("down migration checksum changed: %s", downSum)
	}
}
