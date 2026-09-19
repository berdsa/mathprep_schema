package core

// Dictionary values are kept as typed constants so taskgen and grader share
// the database vocabulary without duplicating string literals.

type Domain string

const (
	DomainNUM Domain = "NUM"
	DomainFRA Domain = "FRA"
	DomainDEC Domain = "DEC"
	DomainGEO Domain = "GEO"
	DomainMEA Domain = "MEA"
	DomainALG Domain = "ALG"
	DomainFUN Domain = "FUN"
	DomainSTA Domain = "STA"
	DomainPRO Domain = "PRO"
	DomainTRG Domain = "TRG"
	DomainLOG Domain = "LOG"
	DomainVEC Domain = "VEC"
	DomainMAT Domain = "MAT"
	DomainCAL Domain = "CAL"
	DomainDIS Domain = "DIS"
)

type GradeBand string

const (
	GradeBand1          GradeBand = "1"
	GradeBand2          GradeBand = "2"
	GradeBand3          GradeBand = "3"
	GradeBand4          GradeBand = "4"
	GradeBand5          GradeBand = "5"
	GradeBand6          GradeBand = "6"
	GradeBand7          GradeBand = "7"
	GradeBand8          GradeBand = "8"
	GradeBand9          GradeBand = "9"
	GradeBand10         GradeBand = "10"
	GradeBand11         GradeBand = "11"
	GradeBandUniversity GradeBand = "UNIVERSITY"
)

type TierCode string

const (
	TierT1 TierCode = "T1"
	TierT2 TierCode = "T2"
	TierT3 TierCode = "T3"
)

type ValidationMethod string

const (
	ValidationMethodExactInt ValidationMethod = "EXACT-INT"
	ValidationMethodExactRat ValidationMethod = "EXACT-RAT"
	ValidationMethodTol      ValidationMethod = "TOL"
	ValidationMethodSet      ValidationMethod = "SET"
	ValidationMethodCanon    ValidationMethod = "CANON"
	ValidationMethodCAS      ValidationMethod = "CAS"
	ValidationMethodBool     ValidationMethod = "BOOL"
	ValidationMethodTuple    ValidationMethod = "TUPLE"
	ValidationMethodMatrix   ValidationMethod = "MATRIX"

	MethodExactInt = ValidationMethodExactInt
)

type EquivalencePolicy string

const (
	EquivalencePolicyStrictForm EquivalencePolicy = "STRICT-FORM"
	EquivalencePolicyEquivClass EquivalencePolicy = "EQUIV-CLASS"
	EquivalencePolicyCASEquiv   EquivalencePolicy = "CAS-EQUIV"
)

type GenerationMode string

const (
	GenerationModeCode     GenerationMode = "CODE"
	GenerationModeHybridAI GenerationMode = "HYBRID-AI"
)

type TaskTypeStatus string

const (
	TaskTypeStatusDraft TaskTypeStatus = "DRAFT"
	TaskTypeStatusGated TaskTypeStatus = "GATED"
	TaskTypeStatusFinal TaskTypeStatus = "FINAL"
)

type Verdict string

const (
	VerdictCorrect     Verdict = "CORRECT"
	VerdictIncorrect   Verdict = "INCORRECT"
	VerdictUnparseable Verdict = "UNPARSEABLE"
)

type ReasonCode string

const (
	ReasonOK                     ReasonCode = "OK"
	ReasonParseError             ReasonCode = "PARSE_ERROR"
	ReasonEmptyInput             ReasonCode = "EMPTY_INPUT"
	ReasonInputTooLong           ReasonCode = "INPUT_TOO_LONG"
	ReasonWrongFormat            ReasonCode = "WRONG_FORMAT"
	ReasonValueMismatch          ReasonCode = "VALUE_MISMATCH"
	ReasonCanonNotReduced        ReasonCode = "CANON_NOT_REDUCED"
	ReasonIncompleteTuple        ReasonCode = "INCOMPLETE_TUPLE"
	ReasonSetCardinalityMismatch ReasonCode = "SET_CARDINALITY_MISMATCH"
	ReasonCASTimeout             ReasonCode = "CAS_TIMEOUT"
)

type RenderTarget string

const (
	RenderTargetPlaintext   RenderTarget = "plaintext"
	RenderTargetUnicodeMath RenderTarget = "unicode-math"
)

type Locale string

const LocaleRuKZ Locale = "ru-KZ"

type UserType string

const (
	UserTypeStudent  UserType = "STUDENT"
	UserTypeGuardian UserType = "GUARDIAN"
	UserTypeAdmin    UserType = "ADMIN"
)
