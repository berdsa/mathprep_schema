# Independent student account to family learning profile link

**Status:** local-development implementation contract; production activation remains disabled pending approved child-data policy and legal review.

## Identity boundary

An independent student registration owns a principal in a `student` tenant. A family-owned learning profile remains in its existing `family` tenant and retains its learner, curriculum-student and child-principal IDs. Linking records an authorization relationship only; it does not merge principals, move tenant ownership, copy or replace phone identities, modify credentials, or infer guardian status from a code or phone number.

## Two-sided state flow

`pending_family → pending_student → active`, with terminal `rejected`, `revoked`, and `expired` states. The student creates a random one-use pairing code with a maximum 15-minute lifetime. Only a SHA-256 digest is stored. The family owner enters the code while signed in, selects one of their own active child profiles, and confirms the selection. The student then reviews the selected profile and confirms or rejects it while signed in as the principal that created the code. The server rechecks family ownership, current learning consent, both active accounts, tenant kinds, status and expiry before activating.

Only one open/active link per independent student and one open/active student per child are allowed. Code consumption, family confirmation, student confirmation, expiry and revocation are one-use transitions. A revoked or rejected link cannot be reopened; create a new pairing attempt. Student sessions continue to authenticate only against their original `student` tenant. The API authorizes access to the family child only through the active link plus the existing family consent checks. A student list query must return only the profile linked to that student; never enumerate family siblings.

## Consent and operating environment

Linking is not parental consent and does not establish who is a legal guardian. The family child profile must already have an active current learning-consent record; link finalization does not create or refresh it. Removing either the active link or family consent blocks future learning access. No prior learning data is copied between accounts.

These endpoints and link-based learning access are allowed only in local development with fictional data. Production startup rejects the synthetic policy. No real child data is accepted until counsel and the product owner approve authority evidence, age-appropriate student assent, policy wording, retention, revocation and appeals. This local pairing step is not school placement; placement continues through the existing authorized school request/approval workflow.

## Storage contract

Migration `000115_student_profile_pairing` adds `mathprep.platform_student_profile_link`. The row stores principal/tenant IDs, selected family/child IDs after family confirmation, a digest for an unconsumed code, explicit confirmation timestamps, a bounded expiry and lifecycle state. It stores no raw pairing code, contact value, OTP, credential or access token. Narrow API column grants, immutable identity columns, trigger-validated transitions and partial unique indexes protect one-use and ownership constraints. Rollback refuses to remove link history.

## Acceptance requirements

- Student initiates; a different family owner can consume the code once and choose only a child in their family with current learning consent; the initiating student confirms the same child.
- Wrong/expired/replayed codes, wrong owner, wrong student session, inactive account, revoked relationship, withdrawn consent and an already-linked student/child fail without exposing another account or profile.
- Phone, email, name, grade and family similarity cannot find, claim, merge, or switch an account.
- No link or consent is created by student registration alone; no learning access is enabled until both authenticated parties confirm and current family consent passes.
- Parent and student revocation immediately blocks future child access; principals, phone identities and curriculum student records remain unchanged.
- Web E2E covers start → parent selection/confirmation → student review/confirmation → linked learning, plus expiry, replay, rejection, revocation and consent withdrawal in RU/KK/EN, using deterministic synthetic fixtures in the existing `mathprep` database.
