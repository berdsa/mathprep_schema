// Package validation contains the shared answer-validation pipeline.
package validation

import (
	"math"
	"regexp"
	"strconv"
	"strings"

	core "github.com/berdsa/mathprep_schema/pkg/core"
)

type Stage string

const (
	StageParse     Stage = "parse"
	StageNormalize Stage = "normalize"
	StageCompare   Stage = "compare"
	StageVerdict   Stage = "verdict"
)

type Result struct {
	Verdict       core.Verdict
	ReasonCode    core.ReasonCode
	Normalized    string
	Stage         Stage
	CorrectAnswer string
}

// Validate dispatches through the task type's declared validation method.
// New validators belong here so the submission handler remains generic.
func Validate(method core.ValidationMethod, raw, correctAnswer string) Result {
	switch method {
	case core.ValidationMethodExactInt:
		return ValidateExactInt(raw, correctAnswer)
	case core.ValidationMethodBool:
		return ValidateBool(raw, correctAnswer)
	case core.ValidationMethodCanon:
		return ValidateCanonList(raw, correctAnswer)
	case core.ValidationMethodTuple:
		return ValidateTuple(raw, correctAnswer)
	case core.ValidationMethodExactRat:
		return ValidateExactRat(raw, correctAnswer)
	case core.ValidationMethodTol:
		return ValidateTol(raw, correctAnswer, 1e-6)
	default:
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
}

func ValidateTol(raw, correctAnswer string, tolerance float64) Result {
	got, err := strconv.ParseFloat(strings.TrimSpace(strings.ReplaceAll(raw, ",", ".")), 64)
	if err != nil {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	want, err := strconv.ParseFloat(strings.TrimSpace(strings.ReplaceAll(correctAnswer, ",", ".")), 64)
	if err != nil {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonParseError, Stage: StageCompare, CorrectAnswer: correctAnswer}
	}
	if math.Abs(got-want) > tolerance {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: strconv.FormatFloat(got, 'f', -1, 64), Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: strconv.FormatFloat(got, 'f', -1, 64), Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

var exactRatInput = regexp.MustCompile(`^\s*([0-9]+)(?:\s*/\s*([0-9]+))?\s*$`)

// ValidateExactRat parses rational answers, reduces both sides for comparison,
// and rejects a fraction that was not submitted in lowest terms.
func ValidateExactRat(raw, correctAnswer string) Result {
	got, gotReduced, reason := parseExactRat(raw)
	if reason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: reason, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	correct, _, correctReason := parseExactRat(correctAnswer)
	if correctReason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonParseError, Stage: StageCompare, CorrectAnswer: correctAnswer}
	}
	if got != correct {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: gotReduced, Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: gotReduced, Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

func parseExactRat(raw string) (canonical, reduced string, reason core.ReasonCode) {
	match := exactRatInput.FindStringSubmatch(raw)
	if len(match) != 3 {
		if strings.TrimSpace(raw) == "" {
			return "", "", core.ReasonEmptyInput
		}
		return "", "", core.ReasonWrongFormat
	}
	numerator, err := strconv.ParseInt(match[1], 10, 64)
	if err != nil {
		return "", "", core.ReasonWrongFormat
	}
	denominator := int64(1)
	if match[2] != "" {
		denominator, err = strconv.ParseInt(match[2], 10, 64)
		if err != nil || denominator == 0 {
			return "", "", core.ReasonWrongFormat
		}
	}
	if denominator < 0 {
		numerator, denominator = -numerator, -denominator
	}
	divisor := gcd64(numerator, denominator)
	reducedNumerator, reducedDenominator := numerator/divisor, denominator/divisor
	reduced = strconv.FormatInt(reducedNumerator, 10)
	if reducedDenominator != 1 {
		reduced += "/" + strconv.FormatInt(reducedDenominator, 10)
	}
	if match[2] != "" && (numerator != reducedNumerator || denominator != reducedDenominator) {
		return "", reduced, core.ReasonCanonNotReduced
	}
	return reduced, reduced, core.ReasonOK
}

func gcd64(a, b int64) int64 {
	if a < 0 {
		a = -a
	}
	for b != 0 {
		a, b = b, a%b
	}
	if a == 0 {
		return 1
	}
	return a
}

var tupleInput = regexp.MustCompile(`^\s*([0-9]{1,3})\s*(?:,|;|ост\.?|остаток)\s*([0-9]{1,3})\s*$`)

// ValidateTuple validates an ordered non-negative integer pair. Separators
// follow the canonical TUPLE contract; components are never sorted.
func ValidateTuple(raw, correctAnswer string) Result {
	match := tupleInput.FindStringSubmatch(strings.ToLower(raw))
	if len(match) != 3 {
		if strings.TrimSpace(raw) != "" && !strings.ContainsAny(raw, ",;ост") {
			return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonIncompleteTuple, Stage: StageParse, CorrectAnswer: correctAnswer}
		}
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	got := match[1] + "," + match[2]
	correct := strings.TrimSpace(correctAnswer)
	correctMatch := tupleInput.FindStringSubmatch(strings.ToLower(correct))
	if len(correctMatch) != 3 {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonParseError, Stage: StageCompare, CorrectAnswer: correctAnswer}
	}
	canonical := correctMatch[1] + "," + correctMatch[2]
	if got != canonical {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: got, Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: got, Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

func ValidateCanonList(raw, correctAnswer string) Result {
	if isRoman(correctAnswer) {
		return ValidateRoman(raw, correctAnswer)
	}
	parts := strings.FieldsFunc(strings.TrimSpace(raw), func(r rune) bool { return r == ',' || r == ';' || r == ' ' })
	if len(parts) == 0 {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	values := make([]int, len(parts))
	for i, p := range parts {
		n, err := strconv.Atoi(p)
		if err != nil {
			return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
		}
		values[i] = n
	}
	for i := 1; i < len(values); i++ {
		for j := i; j > 0 && values[j] < values[j-1]; j-- {
			values[j], values[j-1] = values[j-1], values[j]
		}
	}
	normalized := make([]string, len(values))
	for i, n := range values {
		normalized[i] = strconv.Itoa(n)
	}
	got := strings.Join(normalized, " ")
	if got != strings.TrimSpace(correctAnswer) {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: got, Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: got, Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

var romanInput = regexp.MustCompile(`^\s*([MDCLXVI]+)\s*$`)

func isRoman(value string) bool {
	return romanInput.MatchString(strings.ToUpper(strings.TrimSpace(value)))
}

// ValidateRoman accepts canonical Roman numerals in the inclusive range
// 1..3999. Non-canonical spellings are rejected rather than silently fixed.
func ValidateRoman(raw, correctAnswer string) Result {
	got := strings.ToUpper(strings.TrimSpace(raw))
	if !romanInput.MatchString(got) {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	value, ok := parseRoman(got)
	if !ok {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	normalized := romanFromInt(value)
	if normalized != strings.TrimSpace(correctAnswer) {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: normalized, Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: normalized, Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

func parseRoman(s string) (int, bool) {
	values := map[byte]int{'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
	total := 0
	for i := 0; i < len(s); i++ {
		v, ok := values[s[i]]
		if !ok {
			return 0, false
		}
		if i+1 < len(s) && v < values[s[i+1]] {
			total -= v
		} else {
			total += v
		}
	}
	return total, total >= 1 && total <= 3999 && romanFromInt(total) == s
}

func romanFromInt(n int) string {
	var b strings.Builder
	for _, pair := range []struct {
		value  int
		symbol string
	}{{1000, "M"}, {900, "CM"}, {500, "D"}, {400, "CD"}, {100, "C"}, {90, "XC"}, {50, "L"}, {40, "XL"}, {10, "X"}, {9, "IX"}, {5, "V"}, {4, "IV"}, {1, "I"}} {
		for n >= pair.value {
			b.WriteString(pair.symbol)
			n -= pair.value
		}
	}
	return b.String()
}

// ValidateBool handles the fixed-vocabulary, case-insensitive BOOL contract.
// The stored answer is already canonical; synonyms are normalized before
// comparison so task types do not need their own parsing code.
func ValidateBool(raw, correctAnswer string) Result {
	canonical := map[string]string{"<": "<", "less": "<", "less than": "<", ">": ">", "greater": ">", "greater than": ">", "=": "=", "equal": "=", "equal to": "="}
	normalized, ok := canonical[strings.ToLower(strings.TrimSpace(raw))]
	if !ok {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: core.ReasonWrongFormat, Stage: StageParse, CorrectAnswer: correctAnswer}
	}
	if normalized != correctAnswer {
		return Result{Verdict: core.VerdictIncorrect, ReasonCode: core.ReasonValueMismatch, Normalized: normalized, Stage: StageVerdict, CorrectAnswer: correctAnswer}
	}
	return Result{Verdict: core.VerdictCorrect, ReasonCode: core.ReasonOK, Normalized: normalized, Stage: StageVerdict, CorrectAnswer: correctAnswer}
}

// ParsedExactInt is the parse-stage representation of an EXACT-INT answer.
// Its digits have passed the input contract but have not been numerically
// normalized yet.
type ParsedExactInt struct {
	digits string
}

var exactIntInput = regexp.MustCompile(`^\s*\+?0*([0-9]{1,5})\s*$`)

func ParseExactInt(raw string) (ParsedExactInt, core.ReasonCode, Stage) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ParsedExactInt{}, core.ReasonEmptyInput, StageParse
	}
	if strings.ContainsAny(trimmed, ",.") {
		return ParsedExactInt{}, core.ReasonWrongFormat, StageParse
	}
	if len(trimmed) > 6 {
		return ParsedExactInt{}, core.ReasonInputTooLong, StageParse
	}

	match := exactIntInput.FindStringSubmatch(raw)
	if len(match) != 2 {
		return ParsedExactInt{}, core.ReasonWrongFormat, StageParse
	}
	return ParsedExactInt{digits: match[1]}, core.ReasonOK, StageParse
}

func NormalizeExactInt(parsed ParsedExactInt) (string, core.ReasonCode, Stage) {
	if parsed.digits == "" {
		return "", core.ReasonParseError, StageNormalize
	}

	value, err := strconv.ParseUint(parsed.digits, 10, 64)
	if err != nil {
		return "", core.ReasonParseError, StageNormalize
	}
	return strconv.FormatUint(value, 10), core.ReasonOK, StageNormalize
}

func CompareExactInt(given, correct string) (bool, core.ReasonCode, Stage) {
	if given == correct {
		return true, core.ReasonOK, StageCompare
	}
	return false, core.ReasonValueMismatch, StageCompare
}

// ValidateExactInt evaluates raw against the frozen correct answer stored for
// the task instance. The answer is parsed and normalized independently so a
// malformed frozen answer cannot accidentally grade as a valid mismatch.
func ValidateExactInt(raw, correctAnswer string) Result {
	parsed, reason, stage := ParseExactInt(raw)
	if reason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: reason, Stage: stage, CorrectAnswer: correctAnswer}
	}

	normalized, reason, stage := NormalizeExactInt(parsed)
	if reason != core.ReasonOK {
		return Result{Verdict: core.VerdictUnparseable, ReasonCode: reason, Stage: stage, CorrectAnswer: correctAnswer}
	}

	correctParsed, correctReason, _ := ParseExactInt(correctAnswer)
	if correctReason != core.ReasonOK {
		return Result{
			Verdict:       core.VerdictUnparseable,
			ReasonCode:    core.ReasonParseError,
			Normalized:    normalized,
			Stage:         StageCompare,
			CorrectAnswer: correctAnswer,
		}
	}
	correctNormalized, correctReason, _ := NormalizeExactInt(correctParsed)
	if correctReason != core.ReasonOK {
		return Result{
			Verdict:       core.VerdictUnparseable,
			ReasonCode:    core.ReasonParseError,
			Normalized:    normalized,
			Stage:         StageCompare,
			CorrectAnswer: correctAnswer,
		}
	}

	equal, compareReason, _ := CompareExactInt(normalized, correctNormalized)
	if equal {
		return Result{
			Verdict:       core.VerdictCorrect,
			ReasonCode:    core.ReasonOK,
			Normalized:    normalized,
			Stage:         StageVerdict,
			CorrectAnswer: correctAnswer,
		}
	}
	return Result{
		Verdict:       core.VerdictIncorrect,
		ReasonCode:    compareReason,
		Normalized:    normalized,
		Stage:         StageVerdict,
		CorrectAnswer: correctAnswer,
	}
}
