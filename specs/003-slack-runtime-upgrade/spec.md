# Feature Specification: Supported Slack reporter runtime

**Feature Branch**: `003-slack-runtime-upgrade`
**Created**: 2026-10-13
**Status**: Approved for implementation by operator request
**Input**: Upgrade the shared alarm-to-Slack reporter runtime and test an existing dual-region account configuration. Keep all shared artifacts and commits generic.

## User Scenarios & Testing

### User Story 1 - Supported alarm delivery (Priority: P1)
An operator upgrades the shared monitoring module so Slack alarm reporters use a maintained execution environment while delivering the same alarm information.

**Independent Test**: Process representative SNS alarm envelopes with mocked delivery; verify destination, alarm name, state and region in each payload.

**Acceptance Scenarios**:
1. Given an existing Slack subscription, upgrading the module selects a supported runtime and retains its function identity and SNS wiring.
2. Given ALARM and OK notifications in either deployment region, processing sends the correct state and alarm details to the configured destination.
3. Given delivery failure, the handler retains its existing error behavior.

### User Story 2 - Reviewable account adoption (Priority: P2)
An operator validates the module with both regional reporter configurations before deployment.

**Independent Test**: A credential-free plan/test verifies both reporters and stable identities; a read-only account inventory records the currently deployed runtimes.

**Acceptance Scenarios**:
1. Given primary and secondary region subscriptions, the candidate selects the supported runtime in both.
2. Given existing infrastructure, no production resource is changed or notification sent during offline validation.

### Edge Cases
Retained immutable versions cannot be upgraded in place. Missing or malformed alarm fields must preserve upstream behavior. Non-Slack subscription types remain outside this change.

## Requirements

### Functional Requirements
- FR-001: Shared Slack reporters MUST explicitly use a supported execution environment based on Amazon Linux 2023.
- FR-002: The change MUST preserve consumer inputs, function names, handler, SNS subscription behavior and IAM scope.
- FR-003: Tests MUST exercise the upstream handler shipped by the pinned dependency, including both regional alarm envelopes and delivery failure.
- FR-004: Shared source, fixtures, specs, commit subjects/bodies and PR text MUST contain no customer names, account IDs or secret values.
- FR-005: Validation MUST distinguish offline tests, live read-only evidence, deployment planning and actual deployment.
- FR-006: Production apply, live handler invocation and version deletion MUST remain separate approval boundaries.

## Success Criteria
- SC-001: Every in-scope candidate Slack reporter uses a supported execution environment.
- SC-002: Representative ALARM and OK messages in both regions retain their state, name, destination and region with zero real notifications.
- SC-003: Terraform validation and regression checks pass, and reviewers can identify every changed resource or dependency.
- SC-004: All added shared artifacts and commit text contain zero customer identifiers.

## Assumptions
The authorized implementation is the shared Slack reporter path; unrelated deprecated Python handlers remain a separate workstream. Account adoption requires a versioned monitoring release and a reviewed consumer plan. No shared input expansion or provider-floor change is needed.
