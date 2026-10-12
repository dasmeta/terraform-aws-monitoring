# Feature Specification: CloudWatch Metric Query Account ID Stability

**Feature Branch**: `fix-cloudwatch-metric-query-account-id`  
**Created**: 2026-08-28  
**Status**: Draft  
**Input**: User description: "Fix the DasMeta module so RDS standard CloudWatch alarms do not fail with the AWS provider inconsistent-final-plan error."

## User Scenarios & Testing

### User Story 1 - Apply Standard Metric Alarms Reliably (Priority: P1)

As an operator, I want standard same-account CloudWatch metric alarms created by the alerts submodule to apply without provider final-plan inconsistencies.

**Why this priority**: Standard RDS alarms are blocked when the nested metric query contains an account ID that is unknown during planning.

**Independent Test**: Run a mocked Terraform test for a standard same-account metric alarm and confirm the generated alarm does not set `metric_query.account_id`.

**Acceptance Scenarios**:

1. **Given** a standard metric alert without `account_id`, **When** Terraform plans the alarm, **Then** the alarm does not include a data-source-derived `metric_query.account_id`.
2. **Given** a standard metric alert with a literal `account_id`, **When** Terraform plans the alarm, **Then** the literal account ID remains available for cross-account metrics.

---

### User Story 2 - Preserve Metric Math Behavior (Priority: P1)

As a maintainer, I want metric math alarm paths to keep using `metric_query` where it is required.

**Why this priority**: Fill-insufficient-data, anomaly detection, log-based, and expression alarms depend on metric math support.

**Independent Test**: Review the alerts submodule and confirm only unnecessary same-account account ID defaults are removed.

**Acceptance Scenarios**:

1. **Given** an alert using `fill_insufficient_data`, **When** Terraform renders the alarm inputs, **Then** the metric math query remains configured.
2. **Given** an anomaly-detection or expression alert, **When** Terraform renders the alarm inputs, **Then** the expression query remains configured.

## Functional Requirements

- **FR-001**: Same-account standard metric alarms MUST NOT set `metric_query.account_id` from `data.aws_caller_identity`.
- **FR-002**: Standard metric alarms with an explicit alert-level `account_id` MUST preserve that literal account ID.
- **FR-003**: Metric math alarm paths MUST continue to use `metric_query` where required.
- **FR-004**: The alerts submodule public input contract MUST remain backward compatible.
- **FR-005**: The change MUST include verification that the standard metric alarm path no longer depends on a computed `account_id` inside `metric_query`.

## Key Entities

- **Standard Metric Alert**: Alert entry where `log_based_metric` is false and `anomaly_detection` is false.
- **Metric Query Account ID**: Optional CloudWatch metric query field used for cross-account metrics.
- **Same-Account Metric Alarm**: CloudWatch alarm that omits `account_id` and lets CloudWatch evaluate metrics in the current account.

## Assumptions

- CloudWatch treats omitted metric query `account_id` as the current account for same-account alarms.
- Existing cross-account consumers provide a literal alert-level `account_id`.
- The upstream CloudWatch metric alarm wrapper accepts `null` for optional query attributes.

## Success Criteria

- **SC-001**: A standard metric alert without `account_id` can be planned in a mocked Terraform test without rendering a computed metric-query account ID.
- **SC-002**: Existing alert inputs remain source-compatible for consumers.
- **SC-003**: Existing metric math paths remain configured through `metric_query`.
