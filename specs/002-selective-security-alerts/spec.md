# Feature Specification: Selective Security Service Alerts

**Created**: 2026-09-15
**Status**: Approved by direct implementation request
**Input**: Add YAML true/false controls so operators can receive only GuardDuty, Inspector, or Macie findings instead of noisy recurring Security Hub findings.

## User Scenarios & Testing

### User Story 1 - Select GuardDuty alerts only (Priority: P1)

As an operator, I can disable broad Security Hub imported-finding alerts and enable GuardDuty alerts so repeated Security Hub analysis does not flood the notification channel.

**Acceptance Scenarios**:

1. Given Security Hub alerts are false and GuardDuty alerts are true, only unarchived GuardDuty findings of medium or greater severity are routed automatically.
2. Given a GuardDuty finding is archived or lower than medium severity, it is not routed.

### User Story 2 - Select other security services independently (Priority: P2)

As an operator, I can independently enable Inspector and Macie finding alerts using the same configuration block.

**Acceptance Scenarios**:

1. Inspector routes active HIGH and CRITICAL findings when enabled.
2. Macie routes unarchived HIGH findings when enabled.
3. Disabled services do not create direct finding routes.

### User Story 3 - Preserve existing consumers (Priority: P1)

As an existing consumer, omitting the new configuration keeps current Security Hub automated alert behavior.

### User Story 4 - Enrich Opsgenie GuardDuty alerts (Priority: P1)

As an operator, I can enable the same GuardDuty description enrichment used in production so Opsgenie alerts contain the affected resource, timestamps, finding link, and response guidance.

**Acceptance Scenarios**:

1. Given Opsgenie creates an alert from the SNS event, the updater finds it by the EventBridge event ID and replaces its description with actionable GuardDuty context.
2. Given the Opsgenie alert is not immediately available, the updater retries for the configured bounded interval.
3. Given the SNS message is not a GuardDuty finding, the updater ignores it.
4. Given an Opsgenie lookup or update fails, the Lambda invocation fails so configured retries and failure handling can run.

## Functional Requirements

- **FR-001**: The module MUST expose YAML-friendly boolean selectors for `security_hub`, `guardduty`, `inspector`, and `macie` automated alerts.
- **FR-002**: `security_hub` MUST default to true; direct service selectors MUST default to false.
- **FR-003**: GuardDuty MUST match the verified production pattern: direct GuardDuty findings, severity >= 4, and not archived.
- **FR-004**: Inspector MUST match direct active HIGH and CRITICAL findings.
- **FR-005**: Macie MUST match direct unarchived HIGH findings.
- **FR-006**: Enabled direct service rules MUST target the configured alert SNS topic.
- **FR-007**: The SNS policy MUST allow every managed EventBridge rule to publish.
- **FR-008**: Manual Security Hub actions MUST remain available.
- **FR-009**: Documentation MUST show a GuardDuty-only example.
- **FR-010**: The module MUST retain its existing GuardDuty-aware Slack Lambda implementation without duplicating it.
- **FR-011**: The module MUST optionally create an Opsgenie GuardDuty description-updater Lambda equivalent to the verified production implementation.
- **FR-012**: Enabling the updater MUST require an Opsgenie API key and MUST remain disabled by default.
- **FR-013**: The updater MUST subscribe to the same SNS topic as direct finding notifications.
- **FR-014**: The updater MUST add finding type, title, severity, account, region, affected resource, available remote IP, first/last seen time, occurrence count, finding ID/link, description, and response guidance.
- **FR-015**: The updater MUST propagate failed Opsgenie updates as Lambda invocation errors.

## Assumptions

- Alert selectors control notification routing and do not enable or disable the underlying AWS security services.
- Existing severity behavior is retained: HIGH and CRITICAL for Security Hub; the closest native service equivalents are used for direct events.

## Success Criteria

- Operators can configure GuardDuty-only alert routing with four booleans.
- Existing configurations retain their current automated Security Hub route.
- Terraform validation and focused routing tests pass.
- Opsgenie enrichment unit tests cover formatted content, retries, successful updates, and ignored messages.
