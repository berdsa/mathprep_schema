package validation

import (
	"testing"

	core "github.com/berdsa/mathprep_schema/pkg/core"
)

func TestValidateExactIntCorrect(t *testing.T) {
	result := ValidateExactInt("  +00042  ", "42")

	if result.Verdict != core.VerdictCorrect || result.ReasonCode != core.ReasonOK {
		t.Fatalf("got verdict=%q reason=%q, want CORRECT/OK", result.Verdict, result.ReasonCode)
	}
	if result.Normalized != "42" || result.Stage != StageVerdict {
		t.Fatalf("got normalized=%q stage=%q, want 42/verdict", result.Normalized, result.Stage)
	}
}

func TestValidateExactIntIncorrect(t *testing.T) {
	result := ValidateExactInt("41", "42")

	if result.Verdict != core.VerdictIncorrect || result.ReasonCode != core.ReasonValueMismatch {
		t.Fatalf("got verdict=%q reason=%q, want INCORRECT/VALUE_MISMATCH", result.Verdict, result.ReasonCode)
	}
}

func TestValidateExactIntUnparseable(t *testing.T) {
	result := ValidateExactInt("4.2", "42")

	if result.Verdict != core.VerdictUnparseable || result.ReasonCode != core.ReasonWrongFormat {
		t.Fatalf("got verdict=%q reason=%q, want UNPARSEABLE/WRONG_FORMAT", result.Verdict, result.ReasonCode)
	}
	if result.Stage != StageParse {
		t.Fatalf("got stage=%q, want parse", result.Stage)
	}
}

func TestValidateExactIntBoundary(t *testing.T) {
	tests := []struct {
		name   string
		input  string
		reason core.ReasonCode
	}{
		{name: "five digits accepted", input: "99999", reason: core.ReasonOK},
		{name: "six digits fail grammar", input: "100000", reason: core.ReasonWrongFormat},
		{name: "more than six characters too long", input: "1000000", reason: core.ReasonInputTooLong},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, reason, _ := ParseExactInt(test.input)
			if reason != test.reason {
				t.Fatalf("got reason=%q, want %q", reason, test.reason)
			}
		})
	}
}

func TestValidateBool(t *testing.T) {
	if got := ValidateBool(" Less than ", "<"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateBool("greater", "<"); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateBool("maybe", "<"); got.Verdict != core.VerdictUnparseable {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateBool(" oy ", "Oy"); got.Verdict != core.VerdictCorrect || got.Normalized != "Oy" {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateBool("quadrant I", "I"); got.Verdict != core.VerdictUnparseable {
		t.Fatalf("got %+v", got)
	}
}

func TestValidateCanonList(t *testing.T) {
	if got := ValidateCanonList("3, 1, 2", "1 2 3"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateCanonList("1 3 2", "1 2 4"); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
}

func TestValidateRoman(t *testing.T) {
	tests := []struct {
		input, answer string
		verdict       core.Verdict
	}{
		{"MCMXCIX", "MCMXCIX", core.VerdictCorrect},
		{" xiv ", "XIV", core.VerdictCorrect},
		{"IIII", "IV", core.VerdictUnparseable},
		{"XIV", "XV", core.VerdictIncorrect},
	}
	for _, tc := range tests {
		got := ValidateRoman(tc.input, tc.answer)
		if got.Verdict != tc.verdict {
			t.Errorf("ValidateRoman(%q,%q) = %s, want %s", tc.input, tc.answer, got.Verdict, tc.verdict)
		}
	}
}

func TestValidateTuple(t *testing.T) {
	if got := ValidateTuple("8 ост. 5", "8,5"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateTuple("8", "8,5"); got.ReasonCode != core.ReasonIncompleteTuple {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateTuple("5,8", "8,5"); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
}

func TestValidateSet(t *testing.T) {
	if got := ValidateSet("-2, 5", "5,-2"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateSet("1,1", "1,2"); got.Verdict != core.VerdictUnparseable {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateSet("1,3", "1,2"); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
}

func TestValidateExactRat(t *testing.T) {
	if got := ValidateExactRat("5/12", "5/12"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateExactRat("3/6", "1/2"); got.ReasonCode != core.ReasonCanonNotReduced {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateExactRat("1/3", "1/2"); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateExactRat("1/0", "1/2"); got.Verdict != core.VerdictUnparseable {
		t.Fatalf("got %+v", got)
	}
}

func TestValidateRatio(t *testing.T) {
	if got := ValidateRatio("6:8", "3:4"); got.ReasonCode != core.ReasonCanonNotReduced {
		t.Fatalf("expected unreduced ratio, got %+v", got)
	}
	if got := ValidateRatio("3 : 4", "3:4"); got.Verdict != core.VerdictCorrect {
		t.Fatalf("expected correct ratio, got %+v", got)
	}
}

func TestValidateTol(t *testing.T) {
	if got := ValidateTol("1,0000004", "1", 1e-6); got.Verdict != core.VerdictCorrect {
		t.Fatalf("got %+v", got)
	}
	if got := ValidateTol("1.01", "1", 1e-6); got.Verdict != core.VerdictIncorrect {
		t.Fatalf("got %+v", got)
	}
}
