package migrations

import (
	"os"
	"strings"
	"testing"
)

func paymentCorrelationMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestPaymentCorrelationGrantsStayOnPlatformAPIAndPreserveBillingWrites(t *testing.T) {
	up := paymentCorrelationMigrationSQL(t, "000105_platform_api_payment_correlation_grants.up.sql")
	down := paymentCorrelationMigrationSQL(t, "000105_platform_api_payment_correlation_grants.down.sql")

	for _, want := range []string{
		"GRANT SELECT ON public.payment_attempt TO platform_api_svc",
		"GRANT UPDATE ( provider_invoice_id, provider_payment_id, callback_secret_hash_sha256, status, updated_at ) ON public.payment_attempt TO platform_api_svc",
	} {
		if !strings.Contains(up, want) {
			t.Errorf("up migration is missing required capability: %s", want)
		}
	}
	for _, forbidden := range []string{
		"CREATE ROLE",
		"mathprep_payments_svc",
		"GRANT INSERT",
		"GRANT DELETE",
		"GRANT ALL",
	} {
		if strings.Contains(up, forbidden) {
			t.Errorf("up migration contains out-of-scope capability: %s", forbidden)
		}
	}
	if !strings.Contains(down, "REVOKE UPDATE (provider_invoice_id, callback_secret_hash_sha256) ON public.payment_attempt FROM platform_api_svc") {
		t.Error("down migration does not revoke only the newly introduced UPDATE columns")
	}
	for _, preserved := range []string{"provider_payment_id", "status", "updated_at", "completed_at"} {
		if strings.Contains(down, "REVOKE UPDATE ("+preserved) {
			t.Errorf("down migration revokes a capability owned by 000103: %s", preserved)
		}
	}
}
