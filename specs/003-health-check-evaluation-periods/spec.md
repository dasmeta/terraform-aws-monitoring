# Feature Specification: Health Check Alarm Evaluation Periods

**Feature Branch**: `003-health-check-evaluation-periods`
**Created**: 2026-07-24
**Status**: Draft
**Input**: User description: "Expose Route53 health-check alarm evaluation periods so consumer configs can keep period 300 and evaluation periods 5"

## User Scenarios & Testing

### User Story 1 - Tune Route53 health-check alarm evaluation windows (Priority: P1)

As an operator, I want Route53 health-check main and percentage alarms to accept `evaluation_periods` so noisy external checks can require several consecutive unhealthy datapoints before paging.

**Why this priority**: The alerts submodule currently hardcodes Route53 health-check alarm `evaluation_periods = 1`, causing Terraform to revert manually tuned alarms back to one evaluation period.

**Independent Test**: Configure a health-check fixture with `evaluation_periods = 5` and confirm Terraform validation accepts the input and the module passes the value into the CloudWatch metric-alarm module.

**Acceptance Scenarios**:

1. **Given** a health check defines `main.evaluation_periods = 5`, **When** Terraform renders the main Route53 alarm, **Then** the alarm module receives `evaluation_periods = 5`.
2. **Given** a health check defines `percentage.evaluation_periods = 5`, **When** Terraform renders the percentage Route53 alarm, **Then** the alarm module receives `evaluation_periods = 5`.
3. **Given** a health check omits evaluation-period fields, **When** Terraform renders Route53 alarms, **Then** the current default of `1` is preserved.

### User Story 2 - Keep datapoints aligned with explicit evaluation periods (Priority: P1)

As an operator, I want Route53 health-check alarms to accept `datapoints_to_alarm` so alarm behavior can stay "5 out of 5" when evaluation periods are tuned to 5.

**Why this priority**: Existing alarms can have `datapoints_to_alarm` in state, and omitting it causes Terraform to remove that setting during the same plan that changes evaluation periods.

**Independent Test**: Configure a health-check fixture with `datapoints_to_alarm = 5` and confirm Terraform validation accepts it for both main and percentage alarms.

**Acceptance Scenarios**:

1. **Given** a health check defines `main.datapoints_to_alarm = 5`, **When** Terraform renders the main Route53 alarm, **Then** the alarm module receives `datapoints_to_alarm = 5`.
2. **Given** a health check defines `percentage.datapoints_to_alarm = 5`, **When** Terraform renders the percentage Route53 alarm, **Then** the alarm module receives `datapoints_to_alarm = 5`.
3. **Given** `datapoints_to_alarm` is omitted but `evaluation_periods` is set, **When** Terraform renders Route53 alarms, **Then** `datapoints_to_alarm` defaults to the same value as `evaluation_periods`.

## Functional Requirements

- **FR-001**: Health-check `main` alarm configuration MUST accept optional `evaluation_periods`.
- **FR-002**: Health-check `percentage` alarm configuration MUST accept optional `evaluation_periods`.
- **FR-003**: Health-check `main` alarm configuration MUST accept optional `datapoints_to_alarm`.
- **FR-004**: Health-check `percentage` alarm configuration MUST accept optional `datapoints_to_alarm`.
- **FR-005**: Health-check alarms MUST pass configured `evaluation_periods` into `module "external_health_check-alarms"`.
- **FR-006**: Health-check alarms MUST pass configured `datapoints_to_alarm` into `module "external_health_check-alarms"`.
- **FR-007**: Default behavior MUST remain backward-compatible when new fields are omitted.
- **FR-008**: README documentation MUST expose the new health-check fields.

## Key Entities

- **Health Check Main Alarm**: Route53 `HealthCheckStatus` alarm generated per external health check.
- **Health Check Percentage Alarm**: Route53 `HealthCheckPercentageHealthy` alarm generated per external health check.

## Assumptions

- The default `evaluation_periods` remains `1` to avoid changing existing consumers unless they opt in.
- When `datapoints_to_alarm` is omitted, aligning it with `evaluation_periods` is the least surprising behavior for health-check alarms.
- This change does not alter non-health-check alarm types.

## Success Criteria

- **SC-001**: Consumers can configure Route53 health-check alarms with `period = 300`, `evaluation_periods = 5`, and `datapoints_to_alarm = 5`.
- **SC-002**: Existing health-check consumers that omit the new fields continue to validate with the previous default behavior.
- **SC-003**: The external-health-check test fixture includes explicit evaluation-period and datapoints coverage.
