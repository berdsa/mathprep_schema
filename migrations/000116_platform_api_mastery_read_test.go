package migrations

import (
	"crypto/sha256"
	"fmt"
	"os"
	"strings"
	"testing"
)

func TestPlatformAPIMasteryReadMigrationContract(t *testing.T) {
	upBytes, err := os.ReadFile("000116_platform_api_mastery_read.up.sql")
	if err != nil { t.Fatal(err) }
	downBytes, err := os.ReadFile("000116_platform_api_mastery_read.down.sql")
	if err != nil { t.Fatal(err) }
	up := strings.Join(strings.Fields(string(upBytes)), " ")
	down := strings.Join(strings.Fields(string(downBytes)), " ")
	want := "GRANT SELECT (student_id, domain, tier, ema_score, updated_at) ON public.mastery_topic TO platform_api_svc"
	if !strings.Contains(up, want) { t.Errorf("up migration missing scoped grant %q", want) }
	if !strings.Contains(up, "TO mathprep_platform_local") || !strings.Contains(up, "IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mathprep_platform_local')") { t.Error("up migration must grant the same scoped read to the optional local runtime role") }
	if strings.Contains(up, "GRANT SELECT ON public.mastery_topic") || strings.Contains(up, "GRANT ALL") { t.Error("up migration broadens access beyond the endpoint's columns") }
	if !strings.Contains(down, "REVOKE SELECT (student_id, domain, tier, ema_score, updated_at) ON public.mastery_topic FROM platform_api_svc") || !strings.Contains(down, "FROM mathprep_platform_local") { t.Error("down migration must reverse only the scoped grants") }
	upSum := fmt.Sprintf("%x", sha256.Sum256(upBytes))
	downSum := fmt.Sprintf("%x", sha256.Sum256(downBytes))
	if upSum != "ad39ac7bfe29787e387eb6b0cbc911b8155acc67bb8722971379ab19977eade9" { t.Errorf("up checksum changed: %s", upSum) }
	if downSum != "93fd86a6d9bb612d018e6aa727b73444dfd855266548ac5dfb8218b7297fcdb5" { t.Errorf("down checksum changed: %s", downSum) }
}
