# Feature Specification: GuardDuty Alert Action Text

**Feature Branch**: `fix/guardduty-alert-action`  
**Created**: 2026-11-10  
**Status**: Ready for implementation  
**Input**: Investigate and remediate the Sela GuardDuty MetadataDNSRebind alert without recommending an unrelated AMI patch.

## User Scenarios & Testing

### User Story 1 - Respond to GuardDuty activity (Priority: P1)

As an on-call operator, I need a GuardDuty alert to direct me to investigate the observed activity, so I do not spend incident time patching an image when the finding is about a DNS request.

**Independent Test**: Render the alert title and description for a GuardDuty EC2 finding that includes cluster, node pool, and AMI metadata.

**Acceptance Scenarios**:

1. **Given** a GuardDuty DNS rebinding finding with EKS node and AMI metadata, **when** an immediate or grouped alert is formatted, **then** its title says to investigate the GuardDuty activity and its description does not recommend patching the node image.
2. **Given** the same finding, **when** its description is read, **then** the affected finding and resource remain identifiable.

### User Story 2 - Preserve vulnerability actions (Priority: P2)

As an on-call operator, I need Inspector vulnerability findings to keep their existing patch guidance, so the GuardDuty correction does not alter unrelated response paths.

**Independent Test**: Render an Inspector EC2 image alert before and after the change and compare the action text.

**Acceptance Scenario**:

1. **Given** an Inspector EC2 vulnerability finding with node and AMI metadata, **when** an alert is formatted, **then** it still recommends patching the node image.

### Edge Cases

- A GuardDuty finding may lack cluster or image metadata; its action must still be investigative.
- The formatter must not infer that a DNS lookup proves metadata access or compromise.

## Requirements

### Functional Requirements

- **FR-001**: GuardDuty alerts MUST use an investigation action even when node image metadata is present.
- **FR-002**: Grouped GuardDuty descriptions MUST omit generic patch instructions and state that observed activity and scope need review.
- **FR-003**: Existing Inspector and control-finding action text MUST remain unchanged.
- **FR-004**: Immediate and grouped alert paths MUST share consistent GuardDuty action wording.

## Success Criteria

### Measurable Outcomes

- **SC-001**: All GuardDuty formatter regression cases with node image metadata produce zero patch recommendations.
- **SC-002**: Existing Inspector formatter regression cases pass without changed expected actions.
- **SC-003**: Both immediate and grouped GuardDuty alert descriptions identify an investigation action.

## Assumptions

- This change corrects alert wording only; it does not change finding severity, paging, grouping, suppression, or AWS resources.
- Incident-specific environment classification and source attribution are handled outside this shared formatter fix.
