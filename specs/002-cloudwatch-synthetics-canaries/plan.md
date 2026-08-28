# Implementation Plan: CloudWatch Synthetics Canaries Module

**Branch**: `002-cloudwatch-synthetics-canaries` | **Date**: 2026-07-21 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-cloudwatch-synthetics-canaries/spec.md`

## Summary

Add a new reusable Terraform submodule at `modules/cloudwatch-synthetics/` that provisions AWS CloudWatch Synthetics canaries from a grouped `canaries` map. Each entry creates a canary, least-privilege IAM role, log group, CloudWatch alarm, and shares module-managed S3 artifact storage (or opts into an existing bucket). Four packaged Python check scripts (`soap_wsdl`, `soap_cardinfo`, `rest_cardinfo`, `blackhawk_management`) replace Legacy Gateway PRTG Bash checks. Credentials are fetched from Secrets Manager at runtime via `secret_fields` mapping; failures route to a consumer-supplied SNS topic ARN.

## Technical Context

**Language/Version**: Terraform ~> 1.3, Python 3 (CloudWatch Synthetics `syn-python-selenium-11.0` runtime)
**Primary Dependencies**: hashicorp/aws ~> 5.0, archive provider; optional reuse of `terraform-aws-modules/cloudwatch/aws//modules/metric-alarm` (5.7.2) for alarms consistent with `modules/alerts`
**Storage**: S3 (canary artifacts and script bundles), AWS Secrets Manager (credentials), CloudWatch Logs (execution logs)
**Testing**: Terraform test harness (`tests/*/0-setup.tf`, `1-example.tf`, `2-assert.tf`) + CI matrix entry in `.github/workflows/terraform-test.yaml`
**Target Platform**: AWS (single-region submodule; consumer chooses region via provider)
**Project Type**: Terraform submodule library (`dasmeta/monitoring/aws//modules/cloudwatch-synthetics`)
**Performance Goals**: Default schedule `rate(1 minute)` per canary; timeout configurable per canary (default 60s)
**Constraints**: No customer hostnames/credentials in repo; secret redaction in logs/artifacts; plan-time validation for check types, schedules, ARNs, numeric bounds; zip scripts under `python/` per AWS Synthetics packaging rules
**Scale/Scope**: Initial target ~4–20 canaries per module invocation (Legacy Gateway migration scope); one submodule, four check scripts, four+ test scenarios

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Submodule-First | PASS | New capability ships under `modules/cloudwatch-synthetics/`; root wiring explicitly out of scope |
| II. Speckit Before Module Changes | PASS | Active package at `specs/002-cloudwatch-synthetics-canaries/` with `spec.md`, `plan.md`; `tasks.md` follows via `/speckit.tasks` |
| III. Safe Consumer Interface | PASS | Grouped `canaries` map; plan-time validation; neutral naming; secrets by ARN only |
| IV. Tests And Documentation Together | PASS | README, examples, and tests planned in same implementation change |
| V. Shared Governance By Reference | PASS | Cross-repo policy deferred to `infra-governance`; local constitution followed |

**Post-design re-check**: PASS — no constitution violations; no Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/002-cloudwatch-synthetics-canaries/
├── plan.md              # This file
├── research.md          # Phase 0 — resolved deferred decisions
├── data-model.md        # Phase 1 — entity and validation model
├── quickstart.md        # Phase 1 — consumer usage guide
├── contracts/           # Phase 1 — module and script interfaces
│   ├── module-inputs.md
│   ├── check-types.md
│   └── secrets-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 — created by /speckit.tasks (not this command)
```

### Source Code (repository root)

```text
modules/cloudwatch-synthetics/
├── main.tf                 # Module orchestration entry
├── variables.tf            # Inputs + validation blocks
├── outputs.tf              # Canary ARNs, alarm names, bucket ARN
├── versions.tf             # Provider constraints
├── locals.tf               # Name prefixing, defaults, check-type → script map
├── iam.tf                  # Per-canary execution roles and policies
├── s3.tf                   # Module-managed artifact bucket (conditional)
├── archive.tf              # Zip packaging per check type (python/ layout)
├── canary.tf               # aws_synthetics_canary (for_each)
├── alarms.tf               # CloudWatch metric alarms per canary
├── README.md
├── src/
│   ├── common/
│   │   ├── secrets.py      # GetSecretValue + redaction helpers
│   │   └── logging_utils.py
│   ├── soap_wsdl/python/canary.py
│   ├── soap_cardinfo/python/canary.py
│   ├── rest_cardinfo/python/canary.py
│   └── blackhawk_management/python/canary.py
└── tests/
    ├── basic/              # Module apply smoke test
    ├── check-types/        # One canary per supported check_type
    ├── alarm-on-failure/   # Forced failure → ALARM + SNS wiring
    └── secret-redaction/   # Assert no secret values in logs/artifacts

.github/workflows/terraform-test.yaml   # Add modules/cloudwatch-synthetics to matrix
```

**Structure Decision**: Single Terraform submodule with co-located Python canary scripts and standard repo test layout. Script zips use the AWS-required `python/` folder inside each check-type directory. Shared Python utilities live under `src/common/` and are bundled into each check-type zip via `archive_file`.

## Design Decisions

### Module interface

- **Grouped input**: `canaries` map keyed by stable logical name (e.g. `"legacy-gateway-soap-wsdl"`); optional module-level `name_prefix` for resource naming.
- **Required per canary**: `check_type`, `endpoint_url`, `secret_arn`.
- **Optional per canary**: `schedule`, `timeout_seconds`, `run_config`, `secret_fields`, `environment`, `vpc_config`, `alarm_config`, `tags`, `runtime_version`.
- **Module-level**: `sns_topic_arn`, `artifact_bucket` (create vs existing), `kms_key_arn`, `log_retention_days`, `default_tags`.

### Resource creation pattern

- `for_each = var.canaries` drives canary, IAM role, log group, and alarm resources.
- One **shared** module-managed S3 bucket for artifacts (when `create_artifact_bucket = true`) with per-canary prefix `s3://<bucket>/canaries/<key>/`.
- Per-canary IAM role scoped to: its secret ARN (+ KMS decrypt if configured), artifact bucket prefix, its log group, `cloudwatch:PutMetricData`, and Synthetics service trust.

### Script packaging and runtime

- Default runtime: `syn-python-selenium-11.0`; validate overrides against allowlist of `syn-python-selenium-*` and `syn-python-*` runtimes.
- Package each check type as a zip with handler `canary.handler` at `python/canary.py`.
- Upload script zip to module artifact bucket (S3 key per check type + content hash) and reference via `s3_bucket`/`s3_key`/`s3_version` on `aws_synthetics_canary` (avoids 225KB inline limit and enables clean updates).

### Alarms

- Metric namespace: `CloudWatchSynthetics`; metric: `Success`; dimension: `CanaryName`.
- Defaults: `comparison_operator = LessThanThreshold`, `threshold = 1`, `evaluation_periods = 1`, `datapoints_to_alarm = 1`, `treat_missing_data = breaching`.
- Alarm action: consumer `sns_topic_arn` only (topic not created by module).

### Security

- Secrets resolved at runtime via boto3 `GetSecretValue`; never passed through Terraform variables as values.
- Shared redaction helper masks secret values and common credential keys in exception messages before logging.
- S3 bucket: block public access, bucket owner enforced, TLS-only bucket policy, SSE-KMS when `kms_key_arn` set else SSE-S3.

### Validation (plan time)

- `check_type` ∈ `{soap_wsdl, soap_cardinfo, rest_cardinfo, blackhawk_management}`.
- `schedule` matches `rate(...)` or `cron(...)` pattern.
- `timeout_seconds` between 3 and 840 (AWS Synthetics bounds).
- `secret_arn`, `sns_topic_arn`, optional `kms_key_arn` match ARN regex.
- `vpc_config` requires both `subnet_ids` and `security_group_ids` when present.

## Phases

### Phase 0 — Research (complete)

See [research.md](./research.md) for resolved deferred items: retention defaults, S3 lifecycle, check-type stub schemas, test account strategy.

### Phase 1 — Design & Contracts (complete)

See [data-model.md](./data-model.md), [contracts/](./contracts/), and [quickstart.md](./quickstart.md).

### Phase 2 — Task breakdown (next command)

Run `/speckit.tasks` to generate `tasks.md` with ordered implementation tasks. **Do not edit module source until `tasks.md` exists.**

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Check scripts lack PRTG parity until app-team validation | Ship configurable `secret_fields` + `environment`; document stub assertions in `contracts/check-types.md`; mark schemas as validation-pending |
| Synthetics runtime version deprecation | Allowlist + document upgrade path in README; pin default in one local |
| VPC canaries cannot reach Secrets Manager / S3 / CW | Document required egress (443) and optional VPC endpoints in README/quickstart |
| Terraform provider bug updating runtime without code | Pin script via S3 version; force replacement on runtime/check_type change |
| Secret leakage in artifacts | Redaction helper + dedicated `secret-redaction` test scenario |
| CI cost / flakiness from 1-minute schedules | Tests use `rate(5 minutes)` or `rate(0 minute)` for initial create; alarm test forces single failure |

## Validation Strategy

1. `terraform fmt -check` and `terraform validate` on module and all test directories.
2. Add `modules/cloudwatch-synthetics` to CI terraform-test matrix.
3. Test scenarios:
   - **basic**: two canaries, shared defaults, clean destroy.
   - **check-types**: all four `check_type` values apply without error.
   - **alarm-on-failure**: invalid endpoint or assertion → alarm `ALARM` within one period.
   - **secret-redaction**: inject known secret value; assert absent from CloudWatch log events after forced failure.
4. README terraform-docs generation via pre-commit.
5. No production credentials or customer hostnames in any committed file.

## Files in Scope (implementation phase)

- `modules/cloudwatch-synthetics/**` (new)
- `.github/workflows/terraform-test.yaml` (matrix entry)
- `specs/002-cloudwatch-synthetics-canaries/tasks.md` (via `/speckit.tasks`)

## Out of Scope (this feature)

- Root-module wiring in `health-checks-and-alerts.tf`
- Production credential provisioning
- Legacy Gateway application changes
- Customer-specific naming in examples

## Complexity Tracking

> No constitution violations requiring justification.
