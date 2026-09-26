# CAS receipt migration plan

## Scope

Add a relational receipt mapping between a grader submission identifier and its queued CAS evaluation. This supports idempotent lookup by `(item_id, student_id, idempotency_key)` and lets the grader finalize CAS outcomes using the same submission identifier. The queue remains owned by the CAS evaluation contract; the grader receives read/insert access only.

## Changes

1. Add additive migration `000095_cas_submission_receipt` creating `cas_submission` with `submission_id` as its primary key and foreign key to `cas_evaluation_request(request_id)`, plus foreign keys to `task_instance(item_id)` and `students(user_id)`, the idempotency key, submission timestamp, and unique `(item_id, student_id, idempotency_key)` constraint.
2. Grant `grader_svc` SELECT and INSERT on `cas_submission` and `cas_evaluation_request`, and SELECT on `task_set` for ownership checks. Explicitly leave queue UPDATE unavailable to `grader_svc`.
3. Verify migration, relationships, uniqueness, and grants in a disposable synthetic database. Keep the existing `mathprep` database unchanged.
4. Record evidence, update the graph, and commit only this step's owned files.

## Contract notes

The receipt `submission_id` is the CAS queue `request_id`; the matching id is used when the final verdict is inserted into the existing `submission` table. This migration adds no task type or new CAS operation. It grants no CAS queue update access to the grader.
