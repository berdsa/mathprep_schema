package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestNotificationsAccountLocaleReadMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000120_notifications_account_locale_read.up.sql")
	if err != nil {
		t.Fatal(err)
	}
	downBytes, err := os.ReadFile("000120_notifications_account_locale_read.down.sql")
	if err != nil {
		t.Fatal(err)
	}
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	if !strings.Contains(up, "GRANT SELECT (locale) ON mathprep.platform_accounts TO mathprep_notifications_svc") {
		t.Fatal("notifications service must receive only the account locale column")
	}
	if strings.Contains(up, "GRANT SELECT ON mathprep.platform_accounts") || strings.Contains(up, "GRANT ALL") {
		t.Fatal("migration must not grant broad platform-account access")
	}
	if !strings.Contains(down, "REVOKE SELECT (locale) ON mathprep.platform_accounts FROM mathprep_notifications_svc") {
		t.Fatal("down migration must revoke only the locale read")
	}
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "94475520c759f1e1a4c5c0d893dc48ef99d35517dea186125a1668cdca7139c8" {
		t.Errorf("up migration checksum changed: %s", upSum)
	}
	if downSum != "37a3720db69cdc5a75dc32069d9bbe2db5d7104f0a6f137c0847dbaeb8332560" {
		t.Errorf("down migration checksum changed: %s", downSum)
	}
}
