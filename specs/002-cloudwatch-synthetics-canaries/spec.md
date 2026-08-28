# Feature Specification: CloudWatch Synthetics Canaries Module

**Feature Branch**: `002-cloudwatch-synthetics-canaries`  
**Created**: 2026-07-21  
**Status**: Draft  
**Input**: DMVP-10322 — replace Legacy Gateway PRTG Bash checks with reusable AWS CloudWatch Synthetics monitoring. Implement as submodule `modules/cloudwatch-synthetics/` in `terraform-aws-monitoring` (not a standalone repository). Source design: `infra-governance/docs/superpowers/specs/2026-07-20-cloudwatch-synthetics-module-design.md`.

## User Scenarios & Testing

### User Story 1 - Configure Multiple Canaries From One Module (Priority: P1)

As a platform engineer, I want to define a map of independently configured CloudWatch Synthetics canaries so I can replace duplicated PRTG Bash checks with one reusable Terraform module.

**Why this priority**: This is the core capability — without the `canaries` map and packaged scripts, nothing else delivers value.

**Independent Test**: Apply the module with two canary entries (different check types or endpoints) and confirm each creates its own canary, IAM role, log group, and alarm while sharing module-level defaults where configured.

**Acceptance Scenarios**:

1. **Given** a consumer supplies a `canaries` map with required fields (`check_type`, `endpoint_url`, `secret_arn`), **When** the module is applied, **Then** one Synthetics canary is created per map entry with names derived from the stable map key and optional module name prefix.
2. **Given** optional per-canary settings (schedule, timeout, retries, alarm behavior, tags, VPC), **When** they differ between map entries, **Then** each canary receives its own configuration without requiring separate Terraform modules.
3. **Given** a canary map key or module prefix, **When** names are generated, **Then** no secret value or customer identifier appears in the canary name.

---

### User Story 2 - Run Supported Legacy Gateway Check Types (Priority: P1)

As a platform engineer, I want four supported Python check types packaged with the module so SOAP, REST, and Blackhawk monitoring can migrate off PRTG without custom Terraform per endpoint.

**Why this priority**: DMVP-10322 exists to replace specific Legacy Gateway check families; the module must ship those scripts.

**Independent Test**: Configure one canary per supported `check_type` and verify each runs with the default runtime and retrieves credentials from Secrets Manager at execution time.

**Acceptance Scenarios**:

1. **Given** `check_type` is one of `soap_wsdl`, `soap_cardinfo`, `rest_cardinfo`, or `blackhawk_management`, **When** the canary executes, **Then** the matching packaged Python script is used with default runtime `syn-python-selenium-11.0`.
2. **Given** a runtime override is supplied, **When** it is not a supported Python/Selenium runtime name, **Then** Terraform validation fails before apply.
3. **Given** a secret JSON object and a `secret_fields` mapping, **When** the script runs, **Then** it resolves logical fields to secret keys without Terraform or script source changes per endpoint.

---

### User Story 3 - Secure Execution And Artifact Storage (Priority: P1)

As a security-conscious operator, I want least-privilege IAM, encrypted artifact storage, and secret redaction so canary monitoring does not broaden credential exposure.

**Why this priority**: These checks handle credentials; unsafe defaults would block production adoption.

**Independent Test**: Inspect created IAM policies, S3 bucket settings, and failure logs for a test canary and confirm scope, encryption, and redaction behavior.

**Acceptance Scenarios**:

1. **Given** a canary with its own `secret_arn`, **When** IAM is created, **Then** the role grants `secretsmanager:GetSecretValue` only on that ARN and adds `kms:Decrypt` only when a customer-managed KMS key ARN is supplied.
2. **Given** module-created artifact storage, **When** resources are provisioned, **Then** public access is blocked, ownership is enforced, TLS-only bucket policy applies, and encryption uses the supplied KMS key or AWS managed default.
3. **Given** a script error involving secrets or restricted parameters, **When** the failure is logged, **Then** secret values are redacted before appearing in logs or artifacts.
4. **Given** optional VPC configuration is omitted, **When** the canary runs, **Then** it executes without VPC attachment; when VPC is supplied, subnet and security group IDs are required and egress/DNS expectations are documented.

---

### User Story 4 - Failures Raise Alarms (Priority: P2)

As an on-call engineer, I want a CloudWatch alarm per canary on Synthetics success metrics so endpoint failures page through our existing SNS notification path.

**Why this priority**: Monitoring is only useful if failures surface quickly; alarms are required for operational parity with PRTG.

**Independent Test**: Force a canary failure in non-production and confirm the alarm transitions to `ALARM` and invokes the supplied SNS topic ARN.

**Acceptance Scenarios**:

1. **Given** default alarm settings, **When** a canary run fails, **Then** the alarm uses the Synthetics success metric with `CanaryName` dimension, threshold 1, one evaluation period, one datapoint to alarm, and missing data treated as breaching.
2. **Given** a consumer-supplied SNS topic ARN, **When** the alarm fires, **Then** the topic is used only as an alarm action and remains consumer-owned.
3. **Given** alarm settings are overridden per canary, **When** applied, **Then** threshold, evaluation periods, datapoints, enablement, and missing-data behavior reflect the override.

---

### User Story 5 - Validate Before Production (Priority: P2)

As a module maintainer, I want documentation, examples, and automated tests aligned with DasMeta monitoring repo conventions so the submodule can be consumed as `dasmeta/monitoring/aws//modules/cloudwatch-synthetics`.

**Why this priority**: Repo standards and Spec Kit evidence are required before module-impacting merges.

**Independent Test**: Run formatting/validation and the module test suite in an approved non-production AWS account without secret leakage.

**Acceptance Scenarios**:

1. **Given** the submodule README and example, **When** reviewed, **Then** they describe the `canaries` interface, supported check types, Secrets Manager contract, VPC opt-in, and alarm defaults using neutral `example`/`dasmeta` naming only.
2. **Given** the test suite, **When** executed, **Then** it covers all four check types plus assertion failures, HTTP failures, unavailable endpoints, DNS/TLS/connect failures, timeouts, missing-run alarm behavior, and secret redaction.
3. **Given** a safe lifecycle test, **When** create and destroy run in non-production, **Then** resources are removed cleanly without leaving orphaned secrets in state outputs.

---

### Edge Cases

- What happens when a canary references a secret ARN the role cannot read?
- What happens when an existing artifact bucket opt-in is chosen but preflight attestation preconditions are not met?
- How does the module behave when schedule syntax is invalid or timeout exceeds supported bounds?
- What happens when VPC-enabled canaries lack egress to Secrets Manager, S3, or CloudWatch?
- How are check types treated before application-team validation confirms PRTG parity?

## Requirements

### Functional Requirements

- **FR-001**: The module MUST live at `modules/cloudwatch-synthetics/` inside `terraform-aws-monitoring`.
- **FR-002**: The module MUST accept a grouped `canaries` map keyed by stable logical names with required fields `check_type`, `endpoint_url`, and `secret_arn`.
- **FR-003**: The module MUST support optional per-canary fields for schedule (default `rate(1 minute)`), timeout, retries, alarm behavior, non-secret environment values, `secret_fields` mapping, VPC configuration, and tags.
- **FR-004**: The module MUST validate check types, schedule syntax, numeric bounds, and ARN formats at plan time.
- **FR-005**: The module MUST package four Python check scripts: SOAP WSDL availability, SOAP CardInfo, REST CardInfo, and Blackhawk Network management.
- **FR-006**: The module MUST default runtime to `syn-python-selenium-11.0` and allow constrained runtime overrides.
- **FR-007**: The module MUST create, per canary where applicable: execution IAM role/policy, CloudWatch log group, Synthetics canary, CloudWatch alarm, and optional SNS alarm action wiring.
- **FR-008**: The module MUST create module-managed S3 artifact storage with secure defaults unless the consumer explicitly opts into an existing bucket with documented preflight requirements.
- **FR-009**: Script failures from assertion mismatch, HTTP errors, DNS/TLS/connect errors, or timeouts MUST fail the Synthetics run and emit normal failure metrics.
- **FR-010**: Module examples, tests, and documentation MUST avoid customer-specific names and hostnames.

### Key Entities

- **Canary**: A configured Synthetics monitor with check type, endpoint, secret reference, runtime script, schedule, network mode, and alarm settings.
- **Check Type**: One of four supported Legacy Gateway monitoring patterns with documented request/response assertions and required secret field mappings.
- **Secret Contract**: A Secrets Manager secret referenced by ARN whose JSON keys are mapped through `secret_fields` to script inputs at runtime.
- **Artifact Store**: S3 bucket or prefix used for canary run artifacts, with encryption and access scoped to the canary role.

## Success Criteria

### Measurable Outcomes

- **SC-001**: An engineer can configure four distinct check types through one module invocation without duplicating Terraform per endpoint.
- **SC-002**: Forced failures in non-production produce alarm transitions within one evaluation period using default alarm settings.
- **SC-003**: Automated tests demonstrate no secret values in generated logs or artifacts across failure scenarios.
- **SC-004**: Module documentation and examples allow consumption via `dasmeta/monitoring/aws//modules/cloudwatch-synthetics` without referencing production credentials or customer hostnames.
- **SC-005**: Spec Kit artifacts (`spec.md`, `plan.md`, `tasks.md`) exist before any module-impacting Terraform edits merge.

## Out Of Scope

- Production credentials and monitoring-card data
- Legacy Gateway application/API changes
- Application bug fixes
- Customer-specific Terraform names or hostnames
- Root-module wiring in this feature (optional follow-up after submodule is stable)

## Deferred To Plan

- Exact default retention periods and deletion-protection values
- Check-specific request/response schemas pending application-team validation of current PRTG scripts
- Test harness and non-production deployment/account selection
