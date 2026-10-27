# Feature Specification: Security Hub alert lifecycle and delivery evidence

**Feature Branch**: `003-cspm-alerting-remediation`
**Created**: 2026-10-27
**Status**: Ready for planning
**Input**: Make the Security Hub monitoring submodule support the alerting and failure-evidence portions of `dasmeta/infra-governance` PR #94, preserving its existing public interface.

## User Scenarios & Testing

### User Story 1 - Current critical and high alerts (Priority: P1)

The operator receives alerts for active, unresolved CRITICAL/HIGH findings and avoids new automatic alerts when a finding is resolved or suppressed.

**Independent Test**: Representative finding events match or miss the automatic route according to record, workflow, and severity status.

**Acceptance Scenarios**:

1. **Given** an active unresolved HIGH or CRITICAL finding, **when** it reaches the approved Region, **then** the automatic notification route receives it.
2. **Given** an archived, suppressed, or resolved finding, **when** it is updated, **then** the automatic alert does not match.

### User Story 2 - Inspectable delivery failure (Priority: P2)

The operator can find events that EventBridge failed to publish to the selected SNS topic after retries.

**Independent Test**: A target plan includes a failure destination, bounded retries, and a queue policy allowing the exact EventBridge target to write.

**Acceptance Scenarios**:

1. **Given** a configured notification target, **when** its delivery retries expire, **then** the failed event is retained in a named queue.
2. **Given** a delivery failure, **when** operators inspect exposed identifiers and metrics, **then** the failure destination is unambiguous.

### Edge Cases

- The module may reuse a caller-owned SNS topic; its notification target still owns its own failed-delivery queue.
- An event accepted by SNS can later fail at a subscription; subscription-side evidence remains a separate concern.
- A manual custom-action event has a different source pattern and must retain its route.

## Requirements

### Functional Requirements

- **FR-001**: Preserve current CRITICAL/HIGH severity behavior and manual action support while excluding resolved/suppressed automatic findings.
- **FR-002**: Give every enabled SNS EventBridge notification target an inspectable retry-exhaustion destination.
- **FR-003**: Limit queue permissions to the module's own EventBridge rules.
- **FR-004**: Expose route and failure destination identifiers without finding payloads or credentials.
- **FR-005**: Preserve existing notification input names and default disabled behavior.
- **FR-006**: Demonstrate positive and negative routing cases in module tests.

### Key Entities

- **Finding event**: Current Security Hub finding and state.
- **Notification target**: SNS delivery target for automatic or manual events.
- **Failure queue**: Retention point for target invocation failure.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The active unresolved HIGH and CRITICAL fixtures match; archived, suppressed, and resolved fixtures do not.
- **SC-002**: 100% of enabled notification targets have a failed-delivery queue and explicit retry policy.
- **SC-003**: A reviewer can identify each route and failure queue from outputs without access to secrets.

## Assumptions

- The consuming account defines the approved account and Region scope.
- SNS subscription delivery, acknowledgement, and escalation evidence is assessed separately.
- The account module will consume the next published immutable monitoring release.
