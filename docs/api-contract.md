# HTTP API contract: `taskgen` and `grader`

This document describes the HTTP surface implemented by the current Go code in
`taskgen` and `grader`. It was derived from the handlers, middleware, service
code, repository code, and the current tests; it is not a transcription of
`backend-integration.md`.

The contract is intentionally code-oriented. Where the code and
`backend-integration.md` disagree, the disagreement is recorded in the drift
register at the end instead of being silently resolved.

Primary implementation sources read for this contract:

- `taskgen/internal/api/server.go`
- `taskgen/internal/handler/generation.go`
- `taskgen/internal/middleware/http.go`
- `taskgen/internal/model/generation.go`
- `taskgen/internal/service/generation.go`
- `taskgen/internal/repository/generation.go`
- `grader/internal/server/server.go`
- `schema/pkg/core/constants.go`, `schema/pkg/core/rows.go`, and the shared
  validation pipeline

## Common conventions

- JSON field names are the names shown below.
- UUID values are serialized as JSON strings in the usual canonical UUID form.
- Taskgen writes `Content-Type: application/json` for every response it writes.
- Taskgen's outer middleware always emits `X-Request-ID`. If the request has a
  non-blank `X-Request-ID`, that value is echoed; otherwise taskgen generates a
  UUID. This also applies to authentication failures and unmatched routes.
- No rate limiting, CORS handling, or general authentication is implemented in
  the inspected handlers.

## `taskgen`

The production entry point serves `Server.Routes()`. Authentication is applied
before route dispatch. If `TASKGEN_WEBHOOK_SECRET` is non-empty, the request
must have an `X-Webhook-Secret` header whose value is exactly equal to it. If
the configured secret is empty, this check is disabled.

### POST `/v1/generation-requests`

Creates or replays a generation request. The handler passes only one JSON
decode through `encoding/json`; unknown fields are ignored and trailing input
after the first JSON value is not rejected by the handler.

#### Request

`Content-Type` is not checked by the handler. The JSON object fields are:

| Field | JSON type | Required by code | Validation / meaning |
|---|---|---:|---|
| `student_id` | string containing a UUID | yes | Must decode to a non-zero UUID. |
| `grade` | integer | yes | Must be greater than zero. |
| `topics` | array of strings | yes | Must contain at least one element. Each topic is trimmed by the repository; a blank topic is unsupported. Each topic must resolve to at least one active `GATED` or `FINAL` task type for the requested grade. |
| `count` | integer | yes | Must be in the inclusive range 1–50. |
| `idempotency_key` | string | yes | `strings.TrimSpace` must be non-empty. It is otherwise opaque; the code does not require UUID syntax and does not enforce a length. |

There is no separate ownership field. The student existence check is against
the `students` table.

#### Responses

All JSON responses from this endpoint are newline-terminated by the Go JSON
encoder.

##### `202 Accepted`

Body:

```json
{
  "request_id": "uuid",
  "status": "PENDING"
}
```

Schema:

| Field | JSON type | Required | Values |
|---|---|---:|---|
| `request_id` | string (UUID) | yes | Newly created request ID, or the existing request ID for a replay. |
| `status` | string | yes | The status stored in `generation_request`: `PENDING`, `IN_PROGRESS`, `DONE`, or `FAILED`. |

A replay is still returned with HTTP 202, even when the stored status is
`DONE`, `IN_PROGRESS`, or `FAILED`.

**Idempotency behavior:** the key is scoped to
`(student_id, idempotency_key)`, backed by the database unique constraint. A
matching existing row is returned without creating a new request or event.
The replay reads the row's status at replay time: it returns the current
status, not a frozen snapshot of the first response. For example, a replay
can return `DONE` after the original response returned `PENDING`. There is no
24-hour expiry in the code.

##### `400 Bad Request`

Body schema:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "request validation failed"
  }
}
```

Returned when JSON decoding fails or any request validation rule above fails.

##### `401 Unauthorized`

Body schema:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "webhook secret is invalid or missing"
  }
}
```

Returned by the outer middleware when a non-empty configured secret does not
match `X-Webhook-Secret`.

##### `404 Not Found`

Body schema:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "student was not found"
  }
}
```

Returned when the student does not exist, including the race where the row is
deleted between the initial existence check and the insert.

##### `422 Unprocessable Entity`

Body schema:

```json
{
  "error": {
    "code": "UNSUPPORTED_TYPE",
    "message": "requested topic is not supported for this grade"
  }
}
```

Returned when any requested topic has no matching active task type for the
requested grade.

##### `500 Internal Server Error`

Body schema:

```json
{
  "error": {
    "code": "INTERNAL",
    "message": "internal server error"
  }
}
```

Returned for database, transaction, repository, or other service errors that
are not mapped to the validation, not-found, or unsupported-type cases. The
actual cause is logged, not returned.

##### Method mismatch

The `http.ServeMux` method pattern produces `405 Method Not Allowed` for a
method other than `POST` at this path (subject to the standard library's
method-pattern behavior). This framework-generated response is plain text,
not the taskgen JSON error envelope. Authentication still runs before route
dispatch.

### GET `/v1/generation-requests/{id}`

Gets a generation request. `{id}` must be a UUID. The endpoint has no student
ID in the path and the handler performs no ownership check.

#### Responses

##### `200 OK`, request not `DONE`

```json
{
  "request_id": "uuid",
  "status": "PENDING"
}
```

`status` can be `PENDING`, `IN_PROGRESS`, or `FAILED`. The same shape is used
for `DONE` when the database row has no associated task set.

##### `200 OK`, request `DONE` with a task set

```json
{
  "request_id": "uuid",
  "status": "DONE",
  "task_set_id": "uuid",
  "items": [
    {
      "item_id": "uuid",
      "type_id": "G4-NUM-001",
      "spec_version": "1.0.0",
      "tier": "T1",
      "locale": "ru-KZ",
      "render_target": "plaintext",
      "problem": "257 + 486 = ?"
    }
  ]
}
```

Schema for the optional completed fields:

| Field | JSON type | Required |
|---|---|---:|
| `task_set_id` | string (UUID) | only when status is `DONE` and the joined task set is non-null |
| `items` | array of objects | only when `task_set_id` is present |
| `items[].item_id` | string | yes inside each item |
| `items[].type_id` | string | yes inside each item |
| `items[].spec_version` | string | yes inside each item |
| `items[].tier` | string | yes inside each item; current generated values are tier codes such as `T1` |
| `items[].locale` | string | yes inside each item |
| `items[].render_target` | string | yes inside each item |
| `items[].problem` | string | yes inside each item |

Items are returned in database `item_id` order. The handler does not expose
`params_json`, `correct_answer_json`, seed, or the request's original input
fields.

##### `401 Unauthorized`

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "webhook secret is invalid or missing"
  }
}
```

Same middleware behavior as the POST endpoint.

##### `404 Not Found`

For an invalid UUID or an unknown request ID:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "generation request was not found"
  }
}
```

##### `500 Internal Server Error`

```json
{
  "error": {
    "code": "INTERNAL",
    "message": "internal server error"
  }
}
```

Returned for database or task-listing errors.

### Taskgen unmatched paths

After authentication, the catch-all route returns `404 Not Found` with:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "resource was not found"
  }
}
```

## `grader`

The production entry point serves `Server.Handler()`, which is a single
handler rather than a `ServeMux`. It does not check `X-Webhook-Secret` or
perform any student/resource ownership check.

### POST `/v1/items/{id}/submissions`

Submits and grades an answer. The path `{id}` must be a UUID. The handler
requires a non-blank `X-QR-Token` header, but the current code only checks for
presence after trimming; it does not validate a signature, expiry, item
binding, or token contents.

#### Request

The body is limited with `http.MaxBytesReader` to 64 KiB (`64 << 10` bytes).
`Content-Type` is not checked. Unknown JSON fields are ignored. The handler
decodes one JSON value and does not reject trailing input after that value.

| Field | JSON type | Required by code | Validation / meaning |
|---|---|---:|---|
| `student_id` | string containing a UUID | yes | Must decode to a non-zero UUID. |
| `raw_input` | string | no | If omitted, the zero value `""` is graded. No length validation is performed by the handler. |
| `idempotency_key` | string | yes | Must be exactly non-empty. Whitespace-only strings are accepted; UUID syntax and length are not enforced. |

#### `200 OK` response

```json
{
  "verdict": "CORRECT",
  "reason_code": "OK",
  "correct_answer_display": "743",
  "attempt_index": 1
}
```

All four fields are always emitted:

| Field | JSON type | Required | Values / meaning |
|---|---|---:|---|
| `verdict` | string | yes | `CORRECT`, `INCORRECT`, or `UNPARSEABLE`. |
| `reason_code` | string | yes | Codes produced by the shared validation pipeline: `OK`, `PARSE_ERROR`, `EMPTY_INPUT`, `INPUT_TOO_LONG`, `WRONG_FORMAT`, `VALUE_MISMATCH`, `CANON_NOT_REDUCED`, `INCOMPLETE_TUPLE`, `SET_CARDINALITY_MISMATCH`, or `CAS_TIMEOUT`. Not every method emits every code. |
| `correct_answer_display` | string | yes | For matrix answers, and tolerance answers whose stored JSON begins with `[`, the stored JSON text is preserved. Otherwise the stored JSON is decoded and only a JSON string or number is accepted; strings are returned as-is and numbers are formatted with zero fractional digits. |
| `attempt_index` | integer | yes | `0` for `UNPARSEABLE`; otherwise one greater than the current maximum for this item and student at the time of grading. |

The response is JSON with `Content-Type: application/json` and is newline-
terminated by the Go JSON encoder.

**Idempotency behavior:** the key is scoped to
`(item_id, student_id, idempotency_key)`, backed by a database unique
constraint. On a replay, the code does not insert a second submission, event,
or mastery update. It returns the persisted `verdict`, `reason_code`, and
`attempt_index` with HTTP 200. `correct_answer_display` is recomputed from
the current task-instance answer during the replay; it is not a frozen copy
of the first response.

##### `400 Bad Request`

The handler uses `http.Error`, so the body is plain text rather than a JSON
error object:

```text
validation error
```

The response has status 400 and is returned for malformed/oversized JSON,
zero `student_id`, or an exactly empty `idempotency_key`.

##### `401 Unauthorized`

Plain-text body:

```text
missing QR token
```

Returned when `X-QR-Token` is blank after trimming.

##### `404 Not Found`

Plain-text body is one of:

```text
not found
```

Returned for a path that does not end in `/submissions`, an invalid item UUID,
or an item ID that is not found in the database.

##### `405 Method Not Allowed`

Plain-text body:

```text
method not allowed
```

Returned for any method other than POST, before path, token, or body checks.

##### `500 Internal Server Error`

Plain-text body:

```text
internal
```

Returned for transaction, database, validation-answer conversion, event-log,
mastery, or commit errors. The underlying error is logged and not returned.

There is no handler path that returns HTTP 403, 409, or 429.

## CAS submission lifecycle — approved exception, not yet implemented

For the five genuine CAS types only — `UNI-CAL-002`, `UNI-CAL-003`,
`UNI-CAL-005`, `UNI-ODE-001`, and `UNI-ODE-002` — grading is deliberately
asynchronous. `POST /v1/items/{id}/submissions` creates a
`CAS_EVALUATION_REQUEST` and returns `202 Accepted` with a poll target. The
poll target returns the request status and, once complete, the CAS verdict and
reason code. `CAS_TIMEOUT` is reported as `UNPARSEABLE`, never as
`INCORRECT`.

All non-CAS validation methods remain synchronous and retain the existing
`200 OK` submission response. This is an explicit exception to the normal
submission path because sandboxed symbolic evaluation cannot honestly satisfy
the synchronous `NFR-003` p95 ≤150ms target without imposing an unbounded
request wait. The exception is scoped to the five CAS IDs above; it does not
apply to `CANON`, `SET`, `TUPLE`, or any other ordinary validator.

The queued request carries `operation_type=EQUIVALENCE`, a bounded
`candidate_expression`, a bounded generator-frozen `reference_expression`,
and a type-specific policy object containing the allowed symbols, allowed
functions, and AST/CPU/memory/wall-clock limits. This section records the
approved contract; the endpoint, poll route, and CAS worker remain deferred
until the draft specifications receive confirmation.

## Spec-vs-code drift register

The following are explicit differences between this code-derived contract and
the current `backend-integration.md` text.

1. **Taskgen idempotency retention:** `backend-integration.md` says the
   `(student_id, idempotency_key)` result is reused “within 24h”. The code has
   no time window or expiry; the unique row is reused for as long as it exists.

2. **Taskgen replay status (clarification, not a contradiction):** the
   current taskgen code and test read the existing row's status on every
   replay. The canonical and vendored backend documents already describe the
   status as current, but the contract above states it plainly because this
   behavior was previously a source of confusion.

3. **Authentication mechanism:** the document says the bot webhook should use
   Telegram's signature/secret-token mechanism and leaves the exact header to
   implementation. The current taskgen implementation instead optionally
   enforces exact equality of `X-Webhook-Secret` to `TASKGEN_WEBHOOK_SECRET`.
   This is a shared-secret placeholder, not Telegram signature verification.

4. **Grader QR verification:** the document describes “QR-token verification”
   and the surrounding architecture mentions signed, time-boxed tokens. The
   current grader code only checks that `X-QR-Token` is non-blank; it does not
   verify contents, signature, expiry, or item binding.

5. **Documented error codes not implemented:** the table lists HTTP 403 for
   ownership failures, HTTP 409 `ITEM_ALREADY_FINALIZED`, and HTTP 429
   `RATE_LIMITED` for both services. The current handlers contain no such
   branches, ownership checks, finalization check, or rate limiter. Taskgen
   returns 401 for its configured shared-secret failure; grader has no general
   auth failure beyond the 401 missing-token check.

6. **Error response format:** the table labels 400 as `VALIDATION_ERROR` for
   both services and presents a JSON-style contract. Taskgen does return that
   JSON error code and envelope. Grader returns plain-text `validation error`
   through `http.Error`; it does not return an error code field or JSON
   envelope. Grader's 404, 401, and 500 responses are likewise plain text.

7. **Idempotency-key format:** examples in `backend-integration.md` show UUID
   idempotency keys. Neither implementation enforces UUID syntax. Taskgen
   trims for the emptiness check; grader accepts any non-empty string,
   including whitespace-only input.

8. **Taskgen GET response coverage:** the document shows only a completed
   response with `task_set_id` and `items`. The current handler omits those
   fields for non-`DONE` requests and also omits them for a `DONE` row with no
   joined task set. The actual item object fields are all strings, including
   `item_id` and `task_set_id` as serialized UUID strings.

9. **Grader request requiredness:** the documented example includes
   `raw_input`, but the current decoder/validation does not require it. A
   request can omit `raw_input` and grades the empty string.

10. **Grader replay payload:** the existing document specifies the idempotency
    scope but does not state replay payload behavior. The code returns the
    persisted verdict/reason/attempt while recomputing
    `correct_answer_display` from the current item row; it does not store or
    replay a complete response snapshot.
