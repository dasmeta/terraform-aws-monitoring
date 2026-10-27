# Tasks: Security Hub alert lifecycle and delivery evidence

## Phase 1: Setup

- [X] T001 Create `specs/003-security-hub-cspm-alerting/spec.md`.
- [X] T002 Complete `specs/003-security-hub-cspm-alerting/plan.md` and supporting research/design.

## Phase 2: Foundation

- [X] T003 Inspect current `modules/security-hub/eventbridge.tf` targets and `modules/security-hub/outputs.tf`.

## Phase 3: User Story 1 — Current finding alerts

- [X] T004 [US1] Write native positive/negative pattern tests in `modules/security-hub/tests/cspm_alerting.tftest.hcl`.
- [X] T005 [US1] Filter unresolved findings in `modules/security-hub/eventbridge.tf`.

## Phase 4: User Story 2 — Delivery failure

- [X] T006 [US2] Assert failure queue, retry, and scoped policy in `modules/security-hub/tests/cspm_alerting.tftest.hcl`.
- [X] T007 [US2] Add SQS queue/policy and target retry/DLQ in `modules/security-hub/eventbridge.tf`.
- [X] T008 [US2] Expose non-sensitive rule and queue identifiers in `modules/security-hub/outputs.tf`.
- [X] T009 [US2] Explain receipt/acknowledgement boundary in `modules/security-hub/README.md`.

## Phase 5: Validation

- [X] T010 Run format, init, validate, focused native tests, and `git diff --check`; record results in `specs/003-security-hub-cspm-alerting/quickstart.md`.

**Dependencies**: T003 before US1/US2; T004 before T005 and T006 before T007; T010 after all edits.
