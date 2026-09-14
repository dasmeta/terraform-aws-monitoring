# Tasks: Source-File CloudWatch Synthetics Canaries

**Input**: [spec.md](./spec.md), [plan.md](./plan.md), [research.md](./research.md), [data-model.md](./data-model.md), [public contract](./contracts/module-input.md), and [quickstart.md](./quickstart.md)

**Tests**: Required. The specification requires neutral fixture coverage, static public-boundary checks, Terraform validation, a non-production lifecycle test, and HCP Terraform remote-worker evidence.

**Organization**: Tasks are grouped by user story. Complete Setup and Foundational tasks before implementation. A task marked `[P]` edits independent files and may run in parallel after its prerequisites.

## Phase 1: Setup

**Purpose**: Prepare the module and test layout for the approved pre-release breaking interface.

- [ ] T001 Update the bounded archive-provider/state-exposure guidance in `AGENTS.md` while retaining the public-module ban on customer code and endpoints.
- [X] T002 [P] Create neutral fixture path `modules/cloudwatch-synthetics/tests/basic/fixtures/python/canary.py` with only `handler(event, context)`, then remove `modules/cloudwatch-synthetics/tests/fixtures/python/canary.py`.
- [X] T003 [P] Extend `modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh` with failing checks for the future generic input names, fixed handler/runtime, archive resource, and absence of former ZIP/ARN inputs.

---

## Phase 2: Foundational Contract and Packaging Prerequisites

**Purpose**: Define one safe public interface and the dependencies every user story needs.

**⚠️ CRITICAL**: No user-story implementation starts until this phase is complete.

- [X] T004 Add `hashicorp/archive ~> 2.4` to `modules/cloudwatch-synthetics/versions.tf` without changing existing Terraform or AWS provider compatibility.
- [X] T005 Replace the public object contract in `modules/cloudwatch-synthetics/variables.tf`: use `sns_topic_name`, `source_files`, `secret_name`, and optional non-secret `config`; remove `script_zip_path`, `secret_arn`, and `runtime_version`.
- [X] T006 Add Terraform-1.3-compatible lexical validation in `modules/cloudwatch-synthetics/variables.tf` for non-empty names/maps, canonical `python/...` ZIP destinations, required `python/canary.py`, no `config.secret_name`, and no absolute/traversal/empty-segment source paths; document source symlinks as unsupported.
- [X] T007 Add fixed runtime/handler, normalized config, and collision-resistant archive output-path locals in `modules/cloudwatch-synthetics/locals.tf`, using `path.root`, `name_prefix`, and canary key.

**Checkpoint**: Inputs are generic, no wrapper ARN/value is required, and static checks still fail only for unimplemented packaging/lookup behavior.

---

## Phase 3: User Story 1 — Build a canary from private source files (Priority: P1) 🎯 MVP

**Goal**: A consumer supplies private source-file locations and non-secret configuration; the module creates and uploads an executable ZIP without a manual ZIP command.

**Independent Test**: The neutral fixture uses `source_files` only, creates a ZIP with `python/canary.py` and root `config.json`, uploads a versioned object, and updates its package checksum when source/config changes.

- [X] T008 [P] [US1] Update `modules/cloudwatch-synthetics/tests/basic/0-setup.tf` to remove the test-owned prebuilt archive/provider and keep only neutral AWS fixture resources.
- [X] T009 [US1] Create `modules/cloudwatch-synthetics/package.tf` with one `archive_file` resource per canary, dynamic source entries from `${path.root}/${source_path}`, root generated `config.json`, deterministic file mode, and guarded lifecycle preconditions for source existence.
- [X] T010 [US1] Change `modules/cloudwatch-synthetics/artifact.tf` to upload `archive_file` output paths and checksums rather than consumer ZIP paths, preserving existing artifact bucket policy/versioning behavior.
- [X] T011 [US1] Pin `runtime_version = "syn-python-selenium-11.1"` and `handler = "canary.handler"` in `modules/cloudwatch-synthetics/canary.tf`; keep existing schedule, timeout, VPC, tags, memory, tracing, and dependency behavior.
- [X] T012 [US1] Replace `modules/cloudwatch-synthetics/tests/basic/1-example.tf` with two neutral module instances using same-key `source_files` maps and distinct name prefixes, proving archive output paths cannot collide in one Terraform root.
- [X] T013 [US1] Update `modules/cloudwatch-synthetics/tests/basic/2-assert.tf` and `modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh` to assert package upload/version, required ZIP contract, fixed runtime/handler, generated config ownership, package hash change behavior, and rejected unsafe paths/config aliases.
- [X] T014 [US1] Update source-package descriptions in `modules/cloudwatch-synthetics/outputs.tf` and the module summary comment in `modules/cloudwatch-synthetics/main.tf` without changing output names unnecessarily.

**Checkpoint**: User Story 1 is independently testable with only private source files and no manually created ZIP.

---

## Phase 4: User Story 2 — Reuse an existing secret by name (Priority: P1)

**Goal**: A consumer provides an existing secret name from a workspace output; Terraform never reads its value, while the canary receives only scoped runtime access.

**Independent Test**: One neutral default-key secret and one customer-managed-key secret are looked up by name; no secret is created/changed by the module, and generated role policies contain only expected secret/KMS access.

- [X] T015 [US2] Create `modules/cloudwatch-synthetics/lookups.tf` with per-canary `aws_secretsmanager_secret` lookup by `secret_name` and a resolved KMS-key lookup so IAM can distinguish AWS-managed from customer-managed encryption.
- [X] T016 [US2] Replace secret-ARN IAM statements in `modules/cloudwatch-synthetics/iam.tf` with looked-up secret ARNs and conditional customer-key `kms:Decrypt` scoped by `kms:ViaService` and `kms:EncryptionContext:SecretARN`; retain `kms_key_arn` only for artifact encryption.
- [X] T017 [US2] Add a neutral customer-managed KMS key and corresponding secret fixture in `modules/cloudwatch-synthetics/tests/basic/0-setup.tf`, then update `2-assert.tf` and `3-static-assert.sh` to cover default-key versus custom-key permissions and the no-secret-value boundary.

**Checkpoint**: User Story 2 deploys a canary from a secret name, never a secret value or ARN, with least-privilege runtime policy.

---

## Phase 5: User Story 3 — Use an existing SNS topic by name (Priority: P2)

**Goal**: A consumer passes an SNS topic name and receives a Synthetics failure alarm without needing an ARN.

**Independent Test**: A neutral topic name resolves internally and is the failure alarm action for every enabled fixture canary.

- [X] T018 [US3] Add `aws_sns_topic` lookup by `sns_topic_name` to `modules/cloudwatch-synthetics/lookups.tf` and replace `sns_topic_arn` in `modules/cloudwatch-synthetics/alarms.tf` with its resolved ARN.
- [X] T019 [US3] Update `modules/cloudwatch-synthetics/tests/basic/1-example.tf`, `2-assert.tf`, and `3-static-assert.sh` to pass only topic name and assert the named-topic alarm action contract.

**Checkpoint**: User Story 3 creates failure alarms from a topic name only.

---

## Phase 6: Documentation and Verification

**Purpose**: Make the release safe for public module consumers and prove remote Terraform behavior.

- [X] T020 [P] Rewrite `modules/cloudwatch-synthetics/README.md` with generic source-file usage, ZIP/config contract, source-state and symlink limits, secret runtime flow, and no client identifiers.
- [X] T021 [P] Update `modules/cloudwatch-synthetics/tests/README.md` and `modules/cloudwatch-synthetics/tests/basic/README.md` to describe the neutral automatic-packaging fixture and non-production-only lifecycle test.
- [X] T022 [P] Update `specs/003-synthetics-source-files/contracts/module-input.md` and `specs/003-synthetics-source-files/quickstart.md` after implementation so the direct Terraform and DasMeta YAML examples match final variable names and behavior.
- [X] T023 Run `terraform fmt -check -recursive modules/cloudwatch-synthetics`, `terraform -chdir=modules/cloudwatch-synthetics init -backend=false`, `terraform -chdir=modules/cloudwatch-synthetics validate`, and `bash modules/cloudwatch-synthetics/tests/basic/3-static-assert.sh`; resolve every failure.
- [X] T024 Run `terraform init`, `plan`, `apply`, AWS canary/IAM policy inspection, and `destroy` from `modules/cloudwatch-synthetics/tests/basic` in a dedicated non-production account; do not use production.
- [ ] T025 Run an HCP Terraform saved-plan/apply using `specs/003-synthetics-source-files/quickstart.md` on a clean apply worker, then force recreation of the artifact S3 object without source changes and apply again; record run IDs/URLs and stop for packaging redesign if the archive is unavailable.
- [X] T026 Search `modules/cloudwatch-synthetics` for client-specific identifiers and secret values, regenerate only this module’s README tables with repository tooling, and confirm no unrelated paths are modified.

---

## Dependencies & Execution Order

```text
Setup (T001–T003)
  └─ Foundational contract (T004–T007)
       └─ US1 automatic packaging (T008–T014)  ← MVP
            ├─ US2 secret-name lookup/IAM (T015–T017)
            └─ US3 SNS-name alarm (T018–T019)
                 └─ Documentation and verification (T020–T026)
```

US2 and US3 can be implemented in parallel after US1 establishes the new input contract. They both modify `lookups.tf`, so coordinate or complete them sequentially when working in one branch.

## Parallel Opportunities

- T002 and T003 can proceed alongside the `AGENTS.md` update in T001.
- T004, T005, and T007 touch distinct files, but T006 depends on the final `canaries` object from T005.
- T008 can run while the packaging resource is drafted; T012 cannot begin until T009–T011 establish the interface.
- T020–T022 can run in parallel after US1–US3 are complete.

## Implementation Strategy

1. Deliver the MVP through T014: generic source-file packaging with a neutral fixture.
2. Add T015–T017: existing secret-name lookup and runtime permissions.
3. Add T018–T019: named SNS alarm lookup.
4. Complete T020–T026, including the required HCP Terraform remote-worker proof, before a release/PR.

## Format Validation

All 26 tasks use the required checkbox, sequential task ID, optional parallel marker, user-story label for story work, and exact file path format.
