# Legacy student phone enrollment contract

This contract covers recovery for existing student accounts without a verified phone. It is governed by FR-012 and SCOPE-AMD-06. It does not replace normal registration, guardian-provisioned child setup, or the existing verified-phone new-device flow.

## Trust boundaries and sequence

1. The student submits existing credentials. Auth verifies the password and obtains the selected active student principal and membership from Platform API; the browser supplies no principal, membership, role, guardian, or consent assertion.
2. Platform API creates a random short-lived intent bound to that principal, membership, and the digest of the Auth flow cookie. It returns `phone_required`, the intent ID, and expiry. The intent contains no phone number. No session or trusted-device token is issued.
3. The student enters their own E.164 phone. Auth calls a private Platform API destination-validation operation with the intent ID, cookie digest, and number. Platform API revalidates intent status/expiry/binding, active student membership, and absence of a verified identity, then returns the canonical destination without persisting it.
4. Auth sends OTP to that exact destination through WhatsApp first. SMS fallback is rate-limited and subject to the configured low-cost cap. Redis stores only destination/code digests and intent/device/purpose binding. Auth verifies that the submitted number matches the challenge destination before consuming OTP.
5. After OTP success, Auth calls private Platform API finalization with the same intent, binding, and proven number. Platform API re-locks and revalidates the intent and membership, verifies that no current verified identity exists, atomically inserts the verified identity and consumes/scrubs the intent, and creates trusted-device/session material. Auth stores the session in Redis before returning success and setting the trusted-device cookie.

Any invalid, expired, mismatched, replayed, or inactive flow fails closed. A challenge delivery failure does not create a phone identity or session. The intent is retained for audit/cleanup no longer than 24 hours after expiry or completion. Rate limits apply per IP, intent, and destination; responses must not disclose whether another account owns a phone. Logs must exclude phone numbers, OTPs, passwords, cookie contents, and raw tokens.

## Context switch

A session holder cannot prove a different student's password or phone. Context switching to a student with a verified phone may use the existing OTP challenge, bound to the target student membership and current device flow. If the target student has no verified phone, Platform API rejects the context switch with a generic actionable error; the student must sign out and authenticate directly with their own credentials. No student session is issued from the parent/teacher's context.

## Data and migration boundary

Schema owns the additive `platform_student_phone_enrollment_intent` migration and least-privilege grants. The table has only intent ID, principal ID, membership ID, device digest, lifecycle state, and timestamps; it has no raw phone, OTP, password, guardian, or consent fields. Auth owns OTP challenge and session state in Redis. Platform API owns identity finalization and all authorization checks. Existing MathPrep identity and learner rows are not bulk-updated; legacy users enroll only after proving the destination themselves.

## Production gate

The locally testable technical flow does not establish legal authority to process all ages' phone data or to use WhatsApp/SMS with minors. Production use remains gated on privacy/legal review, messaging provider approval and templates, SMS cost ceilings, phone ownership/reassignment handling, and incident/support procedures.
