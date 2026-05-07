# Feature Specification: Alert Description Metadata

**Feature Branch**: `001-alert-description-metadata`  
**Created**: 2026-05-07  
**Status**: Draft  
**Input**: User description: "use speckit for this changes"

## User Scenarios & Testing

### User Story 1 - Add Client Context to Monitoring Module Inputs (Priority: P1)

As an operator, I want the monitoring module to accept a `client_name` input so alarm descriptions can identify the client even when the dashboard `name` is generic.

**Why this priority**: Without the new input, operators cannot reliably distinguish alarm ownership from the generated descriptions.

**Independent Test**: Review the module input documentation and confirm the root module passes a resolved client value into alert-producing submodules.

**Acceptance Scenarios**:

1. **Given** an operator sets `client_name`, **When** the monitoring module renders alarm configuration, **Then** that value is available to health-check, metric, and expression alert flows.
2. **Given** an operator leaves `client_name` unset or blank, **When** the root module resolves alarm context, **Then** it falls back to the module `name`.

---

### User Story 2 - Enrich Generated Alarm Descriptions (Priority: P1)

As an operator, I want generated CloudWatch alarm descriptions to include client, account, and source metadata so I can identify alarm ownership and navigate to the alarm source quickly.

**Why this priority**: The feature’s main value is richer alarm metadata across all alert types.

**Independent Test**: Inspect the alert module logic and confirm all supported alarm paths use the generated multiline `alarm_description` value.

**Acceptance Scenarios**:

1. **Given** a standard metric alert, **When** its description is generated, **Then** it preserves any existing user description and appends client, account, and source lines.
2. **Given** an expression alert, **When** its description is generated, **Then** it includes client, account, and source lines based on the alarm name.
3. **Given** a Route53 health-check alert, **When** its description is generated, **Then** it includes client, account, and source lines for both main and percentage alarm variants.

---

### User Story 3 - Keep Module Documentation Aligned (Priority: P2)

As an operator, I want module documentation to reflect the new `client_name` input so the feature is discoverable and the expected fallback behavior is documented.

**Why this priority**: Undocumented module inputs make the feature easy to miss and harder to use correctly.

**Independent Test**: Review generated README input tables and confirm `client_name` is described in both the root module and alerts submodule documentation.

**Acceptance Scenarios**:

1. **Given** a user reads the root module README, **When** they inspect the inputs table, **Then** `client_name` is listed with its fallback behavior.
2. **Given** a user reads the alerts submodule README, **When** they inspect the inputs table, **Then** `client_name` is listed as a supported input.

---

### User Story 4 - Cover Metadata Behavior in Example Tests (Priority: P2)

As an operator, I want a dedicated test scenario for alarm metadata behavior so future changes can be validated without changing the existing base example.

**Why this priority**: Dedicated coverage makes the new metadata behavior visible while keeping the current base scenario stable.

**Independent Test**: Review `tests/with-client-name/1-example.tf` and confirm it sets `client_name` and exposes representative account and source metadata expectations without modifying `tests/base`.

**Acceptance Scenarios**:

1. **Given** the dedicated metadata test scenario, **When** a maintainer reviews it, **Then** `client_name` is explicitly configured.
2. **Given** the dedicated metadata test scenario, **When** a maintainer reviews its outputs, **Then** expected metadata includes account and source values derived from the active AWS account and region.
3. **Given** the repository test suite, **When** a maintainer compares scenarios, **Then** `tests/base` remains unchanged and metadata coverage lives in the dedicated folder.

### Edge Cases

- `client_name` is unset or only whitespace.
- An alert does not define a user-facing description.
- Alarm names or health-check paths contain characters that require URL encoding in the CloudWatch console link.

## Functional Requirements

- **FR-001**: The root monitoring module MUST expose an optional `client_name` input.
- **FR-002**: The root monitoring module MUST resolve a non-empty alarm client value by using `client_name` when set, otherwise `name`.
- **FR-003**: The root monitoring module MUST pass the resolved client value to the health-check alerts submodule.
- **FR-004**: The root monitoring module MUST pass the resolved client value to the standard alerts submodule invocation.
- **FR-005**: The root monitoring module MUST pass the resolved client value to the expression-alert submodule invocation.
- **FR-006**: The alerts submodule MUST expose an optional `client_name` input.
- **FR-007**: Standard metric, anomaly-detection, and log-based alarms MUST use a generated multiline `alarm_description` that includes client, account, and source metadata.
- **FR-008**: Expression alarms MUST use the same generated multiline `alarm_description` format as standard metric alarms.
- **FR-009**: Health-check alarms MUST use a generated multiline `alarm_description` for both main and percentage alarms that includes client, account, and source metadata.
- **FR-010**: Existing user-provided alert descriptions MUST be preserved as the first line of generated descriptions when present.
- **FR-011**: Root and alerts-module README documentation MUST describe the `client_name` input.
- **FR-012**: The repository MUST provide a dedicated test scenario under `tests/with-client-name/` that exercises the metadata feature through root-module inputs.
- **FR-013**: The dedicated test scenario MUST set `client_name` explicitly and expose expected metadata for account and source values.
- **FR-014**: The metadata test scenario MUST not require changes to the existing `tests/base` example.

## Key Entities

- **Resolved Client Name**: Final non-empty client value used in alarm descriptions.
- **Alarm Description Metadata**: Multiline description content containing user description, client, account, and source fields.
- **Alarm Source URL**: CloudWatch console URL built from region and alarm name for quick navigation.
- **Alert Variant**: One of standard metric, anomaly-detection, log-based, expression, or Route53 health-check alarm flows.

## Assumptions

- Alarm descriptions are consumed in the AWS CloudWatch console and can safely include newline-separated metadata.
- `data.aws_region.project` and `data.aws_caller_identity.project` are available in the alerts module wherever descriptions are built.
- README updates are maintained through the repository’s existing docs generation flow.

## Success Criteria

- **SC-001**: Operators can configure `client_name` from the root monitoring module without changing existing required inputs.
- **SC-002**: All alarm variants supported by `modules/alerts` produce descriptions containing client, account, and source metadata.
- **SC-003**: Existing descriptive text for alerts remains present in generated alarm descriptions when originally supplied.
- **SC-004**: Module README inputs tables document `client_name` in both the root module and the alerts submodule.
- **SC-005**: Maintainers can inspect `tests/with-client-name/1-example.tf` and see concrete example coverage for `client_name` plus expected account and source metadata.
