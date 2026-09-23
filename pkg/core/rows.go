package core

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type User struct {
	UserID   uuid.UUID
	UserType UserType
}

type Student struct {
	UserID uuid.UUID
	Grade  int
}

type GenerationRequestStatus string

const (
	GenerationRequestStatusPending    GenerationRequestStatus = "PENDING"
	GenerationRequestStatusInProgress GenerationRequestStatus = "IN_PROGRESS"
	GenerationRequestStatusDone       GenerationRequestStatus = "DONE"
	GenerationRequestStatusFailed     GenerationRequestStatus = "FAILED"
)

type GenerationRequest struct {
	RequestID      uuid.UUID
	StudentID      uuid.UUID
	Grade          int
	Topics         json.RawMessage
	Count          int
	Status         GenerationRequestStatus
	IdempotencyKey string
	LeaseExpiresAt *time.Time
	CreatedAt      time.Time
}

type TaskType struct {
	TypeID            string
	Domain            Domain
	Grade             GradeBand
	SpecVersion       string
	GenerationMode    GenerationMode
	Status            TaskTypeStatus
	EquivalencePolicy EquivalencePolicy
	ValidationMethod  ValidationMethod
	Locale            Locale
	AnswerWidget      AnswerWidget
	WidgetConfig      json.RawMessage
}

type TaskTypeTemplate struct {
	TypeID       string
	Locale       Locale
	RenderTarget RenderTarget
	TemplateText string
	SpecVersion  string
}

type TaskSet struct {
	TaskSetID      uuid.UUID
	StudentID      uuid.UUID
	RequestID      uuid.UUID
	IssuedAt       time.Time
	IdempotencyKey string
}

type TaskInstance struct {
	ItemID            uuid.UUID
	TypeID            string
	SpecVersion       string
	Tier              TierCode
	Locale            Locale
	RenderTarget      RenderTarget
	Seed              int64
	ParamsJSON        json.RawMessage
	ProblemText       string
	CorrectAnswerJSON json.RawMessage
	TaskSetID         uuid.UUID
}

type Submission struct {
	SubmissionID   uuid.UUID
	ItemID         uuid.UUID
	StudentID      uuid.UUID
	RawInput       string
	Verdict        Verdict
	ReasonCode     ReasonCode
	AttemptIndex   int
	SubmittedAt    time.Time
	IdempotencyKey string
}

type MasteryTopic struct {
	StudentID uuid.UUID
	Domain    Domain
	Tier      TierCode
	EMAScore  float64
	UpdatedAt time.Time
}

type EventLog struct {
	EventID     uuid.UUID
	EventType   EventType
	OccurredAt  time.Time
	PayloadJSON json.RawMessage
}

type CASEvaluationRequest struct {
	RequestID           uuid.UUID
	RequesterID         uuid.UUID
	SessionID           string
	OperationType       CASEvaluationOperationType
	CandidateExpression string
	ReferenceExpression string
	PolicyJSON          json.RawMessage
	Status              CASEvaluationStatus
	Verdict             *Verdict
	ReasonCode          *ReasonCode
	ResultJSON          json.RawMessage
	CreatedAt           time.Time
	StartedAt           *time.Time
	CompletedAt         *time.Time
	LeaseExpiresAt      *time.Time
	HeartbeatAt         *time.Time
	WallDeadlineAt      time.Time
	AttemptCount        int
}

// Row aliases make the database-facing purpose explicit while keeping the
// short entity names convenient for callers.
type UserRow = User
type StudentRow = Student
type GenerationRequestRow = GenerationRequest
type TaskTypeRow = TaskType
type TaskSetRow = TaskSet
type TaskInstanceRow = TaskInstance
type SubmissionRow = Submission
type MasteryTopicRow = MasteryTopic
type EventLogRow = EventLog
type CASEvaluationRequestRow = CASEvaluationRequest
