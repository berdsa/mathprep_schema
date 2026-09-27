package migrations

import (
	"os"
	"strings"
	"testing"
)

func halykInvoiceMigrationSQL(t *testing.T, name string) string {
	t.Helper()
	data, err := os.ReadFile(name)
	if err != nil {
		t.Fatalf("read %s: %v", name, err)
	}
	return strings.Join(strings.Fields(string(data)), " ")
}

func TestHalykInvoiceSuffixIndexIsProviderScopedAndReversible(t *testing.T) {
	up := halykInvoiceMigrationSQL(t, "000106_halyk_invoice_suffix_uniqueness.up.sql")
	down := halykInvoiceMigrationSQL(t, "000106_halyk_invoice_suffix_uniqueness.down.sql")
	want := "CREATE UNIQUE INDEX payment_attempt_halyk_invoice_suffix6_uq ON public.payment_attempt (right(provider_invoice_id, 6)) WHERE provider_code = 'halyk_epay' AND provider_invoice_id IS NOT NULL"
	if !strings.Contains(up, want) {
		t.Fatalf("up migration is missing the provider-scoped suffix constraint: %s", want)
	}
	if !strings.Contains(down, "DROP INDEX public.payment_attempt_halyk_invoice_suffix6_uq") {
		t.Fatal("down migration does not drop the Halyk suffix index")
	}
	if strings.Contains(up, "ALTER TABLE") || strings.Contains(up, "DROP INDEX") {
		t.Fatal("up migration changes unrelated constraints or indexes")
	}
}
