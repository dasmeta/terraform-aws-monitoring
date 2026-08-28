# Tasks: CloudWatch Synthetics Canaries Module

**Input**: Design documents from `/specs/002-cloudwatch-synthetics-canaries/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included — spec User Story 5 and per-story independent test criteria require automated test scenarios.

**Organization**: Tasks grouped by user story (US1–US5) per spec priorities. See Dependencies for recommended execution order when stories overlap.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story label (US1–US5)
- All tasks include exact file paths

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize module directory and provider constraints

- [x] T001 Create module directory scaffold (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `versions.tf`, `iam.tf`, `s3.tf`, `archive.tf`, `canary.tf`, `alarms.tf`, `README.md`) under `modules/cloudwatch-synthetics/`
- [x] T002 [P] Create `modules/cloudwatch-synthetics/versions.tf` with Terraform `~> 1.3`, AWS `~> 5.0`, and `hashicorp/archive` provider constraints
- [x] T003 [P] Create `modules/cloudwatch-synthetics/.gitignore` ignoring `builds/` zip artifacts and local Terraform state

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core module contract, naming, and shared helpers — MUST complete before user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement module input variables and plan-time validation blocks in `modules/cloudwatch-synthetics/variables.tf` per `specs/002-cloudwatch-synthetics-canaries/contracts/module-inputs.md` and `data-model.md` validation rules V-001–V-009
- [x] T005 Implement naming helpers, check-type → script path map, and default value locals in `modules/cloudwatch-synthetics/locals.tf` per `specs/002-cloudwatch-synthetics-canaries/research.md` §9
- [x] T006 Implement module outputs (`canary_arns`, `canary_names`, `alarm_arns`, `artifact_bucket_arn`, `execution_role_arns`) in `modules/cloudwatch-synthetics/outputs.tf`
- [x] T007 Implement shared Secrets Manager fetch and redaction helpers in `modules/cloudwatch-synthetics/src/common/secrets.py` per `specs/002-cloudwatch-synthetics-canaries/contracts/secrets-contract.md`
- [x] T008 [P] Implement shared logging utilities in `modules/cloudwatch-synthetics/src/common/logging_utils.py`
- [x] T009 Implement module orchestration wiring in `modules/cloudwatch-synthetics/main.tf` referencing resource files without creating resources yet

**Checkpoint**: Module contract, locals, outputs, and Python shared libs ready — user story phases can begin

---

## Phase 3: User Story 1 — Configure Multiple Canaries From One Module (Priority: P1) 🎯 MVP

**Goal**: Consumers define a `canaries` map; each entry gets its own canary, IAM role, and log group with shared module defaults and safe naming

**Independent Test**: Apply with two canary entries (different check types or endpoints); confirm separate canary, IAM role, log group, and alarm per entry with shared defaults

### Implementation for User Story 1

- [x] T010 [US1] Implement per-canary IAM execution roles and trust policy in `modules/cloudwatch-synthetics/iam.tf` (base structure; least-privilege refined in US3)
- [x] T011 [US1] Implement per-canary CloudWatch log groups with configurable retention in `modules/cloudwatch-synthetics/canary.tf`
- [x] T012 [US1] Implement `aws_synthetics_canary` resources with `for_each = var.canaries` in `modules/cloudwatch-synthetics/canary.tf` including schedule, timeout, tags, and environment wiring
- [x] T013 [US1] Implement sanitized canary name generation from `name_prefix` + map key in `modules/cloudwatch-synthetics/locals.tf` ensuring no endpoint or secret values appear in names
- [x] T014 [US1] Wire per-canary optional overrides (schedule, timeout_seconds, retries, tags, environment) in `modules/cloudwatch-synthetics/canary.tf`

### Tests for User Story 1

- [x] T015 [P] [US1] Create provider and SNS fixture in `modules/cloudwatch-synthetics/tests/basic/0-setup.tf`
- [x] T016 [US1] Create two-canary module invocation example in `modules/cloudwatch-synthetics/tests/basic/1-example.tf` using neutral `example.com` hostnames
- [x] T017 [US1] Create assertions for two canaries, two IAM roles, and two log groups in `modules/cloudwatch-synthetics/tests/basic/2-assert.tf`
- [x] T018 [P] [US1] Document basic test scenario in `modules/cloudwatch-synthetics/tests/basic/README.md`

**Checkpoint**: Two-canary apply succeeds; resources named from map keys; per-canary config overrides work

---

## Phase 4: User Story 2 — Run Supported Legacy Gateway Check Types (Priority: P1)

**Goal**: Ship four packaged Python check scripts with S3 zip deployment and runtime validation

**Independent Test**: Configure one canary per `check_type`; verify each uses the correct script, default runtime, and resolves credentials via `secret_fields` at execution time

### Implementation for User Story 2

- [x] T019 [P] [US2] Implement WSDL availability check stub in `modules/cloudwatch-synthetics/src/soap_wsdl/python/canary.py` per `specs/002-cloudwatch-synthetics-canaries/contracts/check-types.md`
- [x] T020 [P] [US2] Implement SOAP CardInfo check stub in `modules/cloudwatch-synthetics/src/soap_cardinfo/python/canary.py` per `specs/002-cloudwatch-synthetics-canaries/contracts/check-types.md`
- [x] T021 [P] [US2] Implement REST CardInfo check stub in `modules/cloudwatch-synthetics/src/rest_cardinfo/python/canary.py` per `specs/002-cloudwatch-synthetics-canaries/contracts/check-types.md`
- [x] T022 [P] [US2] Implement Blackhawk management check stub in `modules/cloudwatch-synthetics/src/blackhawk_management/python/canary.py` per `specs/002-cloudwatch-synthetics-canaries/contracts/check-types.md`
- [x] T023 [US2] Implement zip packaging with `python/canary.py` layout and S3 upload in `modules/cloudwatch-synthetics/archive.tf` using content hash in object keys
- [x] T024 [US2] Wire `s3_bucket`/`s3_key`/`s3_version` script references and handler `canary.handler` in `modules/cloudwatch-synthetics/canary.tf`
- [x] T025 [US2] Add `runtime_version` allowlist validation and default `syn-python-selenium-11.0` in `modules/cloudwatch-synthetics/variables.tf`
- [x] T026 [US2] Pass `ENDPOINT_URL`, `SECRET_ARN`, `SECRET_FIELDS`, and `CHECK_TYPE` environment variables from Terraform in `modules/cloudwatch-synthetics/canary.tf`

### Tests for User Story 2

- [x] T027 [P] [US2] Create Secrets Manager fixtures and provider setup in `modules/cloudwatch-synthetics/tests/check-types/0-setup.tf`
- [x] T028 [US2] Create one-canary-per-check-type example in `modules/cloudwatch-synthetics/tests/check-types/1-example.tf`
- [x] T029 [US2] Create plan/apply assertions for four canaries with distinct check types in `modules/cloudwatch-synthetics/tests/check-types/2-assert.tf`
- [x] T030 [P] [US2] Document check-types test scenario in `modules/cloudwatch-synthetics/tests/check-types/README.md`

**Checkpoint**: All four check types deploy; runtime override validation rejects unsupported values; scripts bundle and upload correctly

---

## Phase 5: User Story 3 — Secure Execution And Artifact Storage (Priority: P1)

**Goal**: Least-privilege IAM, encrypted S3 artifacts, secret redaction, and optional VPC

**Independent Test**: Inspect IAM policies, S3 settings, and failure logs; confirm scope, encryption, and redaction behavior

### Implementation for User Story 3

- [x] T031 [US3] Implement module-managed S3 artifact bucket with block public access, versioning, lifecycle expiration, and encryption in `modules/cloudwatch-synthetics/s3.tf` per `specs/002-cloudwatch-synthetics-canaries/research.md` §1–§2
- [x] T032 [US3] Add TLS-only bucket policy and bucket-owner-enforced ownership controls in `modules/cloudwatch-synthetics/s3.tf`
- [x] T033 [US3] Harden per-canary IAM policies in `modules/cloudwatch-synthetics/iam.tf` scoping `secretsmanager:GetSecretValue` to canary `secret_arn` and conditional `kms:Decrypt` on `var.kms_key_arn`
- [x] T034 [US3] Scope S3 and CloudWatch Logs permissions to per-canary prefixes and log groups in `modules/cloudwatch-synthetics/iam.tf`
- [x] T035 [US3] Integrate `src/common/secrets.py` redaction into all four check scripts under `modules/cloudwatch-synthetics/src/*/python/canary.py`
- [x] T036 [US3] Add optional `vpc_config` block to `modules/cloudwatch-synthetics/canary.tf` with required subnet and security group validation
- [x] T037 [US3] Support existing artifact bucket opt-in (`create_artifact_bucket = false`, `artifact_bucket_name`) in `modules/cloudwatch-synthetics/s3.tf` and `modules/cloudwatch-synthetics/variables.tf`

### Tests for User Story 3

- [x] T038 [P] [US3] Create dummy secret and forced-failure fixture in `modules/cloudwatch-synthetics/tests/secret-redaction/0-setup.tf`
- [x] T039 [US3] Create canary example that triggers script failure in `modules/cloudwatch-synthetics/tests/secret-redaction/1-example.tf`
- [x] T040 [US3] Assert secret values absent from CloudWatch log events in `modules/cloudwatch-synthetics/tests/secret-redaction/2-assert.tf`
- [x] T041 [P] [US3] Document secret-redaction test scenario and VPC egress requirements in `modules/cloudwatch-synthetics/tests/secret-redaction/README.md`

**Checkpoint**: IAM scoped per secret; S3 secure defaults enforced; failure logs redact credentials; VPC opt-in validated

---

## Phase 6: User Story 4 — Failures Raise Alarms (Priority: P2)

**Goal**: CloudWatch alarm per canary on Synthetics `Success` metric with SNS notification to consumer topic

**Independent Test**: Force canary failure in non-production; confirm alarm transitions to `ALARM` and targets supplied SNS topic ARN

### Implementation for User Story 4

- [x] T042 [US4] Implement per-canary CloudWatch alarms on `CloudWatchSynthetics`/`Success` in `modules/cloudwatch-synthetics/alarms.tf` with defaults from `specs/002-cloudwatch-synthetics-canaries/research.md` §5
- [x] T043 [US4] Wire consumer `sns_topic_arn` as alarm action only (no topic creation) in `modules/cloudwatch-synthetics/alarms.tf`
- [x] T044 [US4] Support per-canary `alarm_config` overrides (threshold, evaluation periods, datapoints, enablement, treat_missing_data) in `modules/cloudwatch-synthetics/alarms.tf`
- [x] T045 [US4] Expose alarm ARNs in `modules/cloudwatch-synthetics/outputs.tf`

### Tests for User Story 4

- [x] T046 [P] [US4] Create SNS topic and failing-endpoint fixture in `modules/cloudwatch-synthetics/tests/alarm-on-failure/0-setup.tf`
- [x] T047 [US4] Create canary pointed at `https://httpbin.org/status/500` in `modules/cloudwatch-synthetics/tests/alarm-on-failure/1-example.tf`
- [x] T048 [US4] Assert alarm enters `ALARM` state and references SNS topic in `modules/cloudwatch-synthetics/tests/alarm-on-failure/2-assert.tf`
- [x] T049 [P] [US4] Document alarm-on-failure test scenario in `modules/cloudwatch-synthetics/tests/alarm-on-failure/README.md`

**Checkpoint**: Failed canary run triggers alarm within one evaluation period; SNS topic wired as consumer-owned action

---

## Phase 7: User Story 5 — Validate Before Production (Priority: P2)

**Goal**: README, examples, CI integration, and repo-standard validation aligned with DasMeta conventions

**Independent Test**: Run formatting/validation and full module test suite in approved non-production AWS account without secret leakage

### Implementation for User Story 5

- [x] T050 [US5] Write submodule README with interface, check types, secrets contract, VPC, and alarm defaults in `modules/cloudwatch-synthetics/README.md` using neutral `example`/`dasmeta` naming only
- [x] T051 [US5] Add HCL usage example from `specs/002-cloudwatch-synthetics-canaries/quickstart.md` to `modules/cloudwatch-synthetics/README.md`
- [x] T052 [US5] Add `modules/cloudwatch-synthetics` entry to CI matrix in `.github/workflows/terraform-test.yaml`
- [x] T053 [P] [US5] Create consolidated test index in `modules/cloudwatch-synthetics/tests/README.md` listing all four scenarios and coverage matrix

**Checkpoint**: Documentation complete; CI runs module tests; no customer hostnames or credentials in committed files

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup across all stories

- [x] T054 [P] Run `terraform fmt -recursive modules/cloudwatch-synthetics/` and fix formatting
- [x] T055 Run `terraform validate` in each test directory under `modules/cloudwatch-synthetics/tests/*/`
- [x] T056 Verify clean `terraform apply` + `terraform destroy` lifecycle in `modules/cloudwatch-synthetics/tests/basic/` without orphaned secrets in outputs
- [x] T057 [P] Cross-check implemented interface against `specs/002-cloudwatch-synthetics-canaries/contracts/module-inputs.md` and update README input table if drift found

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **User Stories (Phases 3–7)**: All depend on Foundational completion
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|-------|
| **US1** | Foundational | Canary/IAM/log group core; full run needs US2 scripts |
| **US2** | Foundational, US1 canary.tf | Scripts attach to canary resources from US1 |
| **US3** | US1 IAM/S3, US2 scripts | Hardens existing resources; redaction needs scripts |
| **US4** | US1 canaries | Alarms require canary names |
| **US5** | US1–US4 | Docs/CI cover complete module |

### Recommended Execution Order (despite phase numbering)

1. Phase 1 → Phase 2 (Setup + Foundational)
2. Phase 3 US1 (canary map, IAM, log groups)
3. Phase 4 US2 (scripts + S3 packaging)
4. Phase 5 US3 (security hardening + redaction tests)
5. Phase 6 US4 (alarms + failure tests)
6. Phase 7 US5 (README + CI)
7. Phase 8 (Polish)

### Parallel Opportunities

- **Phase 1**: T002, T003 in parallel
- **Phase 2**: T008 parallel with T007 after T004–T006
- **Phase 4 US2**: T019–T022 (all four scripts) in parallel
- **Phase 4 US2 tests**: T027, T030 in parallel with implementation after T026
- **Phase 5 US3 tests**: T038, T041 in parallel
- **Phase 6 US4 tests**: T046, T049 in parallel
- **Phase 7 US5**: T053 parallel with T050–T052
- **Phase 8**: T054, T057 in parallel

### Parallel Example: User Story 2 Scripts

```bash
# Launch all four check scripts together:
Task T019: modules/cloudwatch-synthetics/src/soap_wsdl/python/canary.py
Task T020: modules/cloudwatch-synthetics/src/soap_cardinfo/python/canary.py
Task T021: modules/cloudwatch-synthetics/src/rest_cardinfo/python/canary.py
Task T022: modules/cloudwatch-synthetics/src/blackhawk_management/python/canary.py
```

---

## Implementation Strategy

### MVP First (User Story 1 + minimal US2)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US1 (canary map, IAM, log groups)
4. Complete Phase 4: US2 with at least one script (`soap_wsdl`) to validate end-to-end run
5. **STOP and VALIDATE**: `tests/basic/` apply/destroy in non-prod

### Incremental Delivery

1. Setup + Foundational → contract ready
2. US1 + US2 → canaries run with all check types → MVP
3. US3 → production-safe IAM/S3/redaction
4. US4 → operational alarms
5. US5 → docs, CI, merge-ready

### Task Summary

| Phase | Story | Task IDs | Count |
|-------|-------|----------|-------|
| Setup | — | T001–T003 | 3 |
| Foundational | — | T004–T009 | 6 |
| US1 | Configure Multiple Canaries | T010–T018 | 9 |
| US2 | Legacy Gateway Check Types | T019–T030 | 12 |
| US3 | Secure Execution | T031–T041 | 11 |
| US4 | Failure Alarms | T042–T049 | 8 |
| US5 | Validate Before Production | T050–T053 | 4 |
| Polish | — | T054–T057 | 4 |
| **Total** | | **T001–T057** | **57** |

### Independent Test Criteria (per story)

| Story | Independent Test |
|-------|------------------|
| US1 | Two-canary apply; separate canary/IAM/log group per map entry; safe naming |
| US2 | Four check types deploy; runtime validation; Secrets Manager via `secret_fields` |
| US3 | IAM scoped to secret ARN; S3 encrypted/blocked; logs redact secrets on failure |
| US4 | Forced failure → alarm `ALARM` → consumer SNS topic |
| US5 | README + CI + full test suite pass in non-prod without secret leakage |

### Suggested MVP Scope

**User Story 1 + User Story 2** (Phases 1–4, tasks T001–T030): delivers configurable multi-canary module with all four check types — minimum viable replacement for PRTG Bash checks.

---

## Notes

- Root-module wiring is **out of scope** (per spec); do not edit `health-checks-and-alerts.tf` or root `vaiables.tf`
- Check script assertions are **stubs** pending application-team PRTG parity validation; update scripts in-place when confirmed
- Use neutral hostnames only: `example.com`, `httpbin.org` in tests
- Commit after each phase checkpoint
- Speckit gate satisfied once this `tasks.md` exists alongside `spec.md` and `plan.md` before module source edits
