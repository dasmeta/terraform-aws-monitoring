# Feature Specification: Consistent notification package creation

**Branch**: 002-teams-package-consistency
**Created**: 2026-11-09
**Status**: Approved for implementation
**Input**: Keep Teams enabled and fix/release the shared monitoring module after a clean HCP run fails when a generated ZIP changes from missing to present.

## User Scenarios & Testing

### User Story 1 - Deploy Teams notifications from a clean runner (Priority: P1)

An operator can deploy notification subscriptions without previously generated packages.

**Independent test**: Apply actual subscription modules with mocked cloud operations and real archive creation from an empty build directory.

**Acceptance scenarios**:

1. Given no ZIP exists and archive creation is deferred until apply, notification deployment completes without an inconsistent filesystem-function result.
2. Given two Teams destinations, both subscriptions deploy in one run.
3. Given the generated ZIP exists, a subsequent run remains valid.

## Requirements

- FR-001: Preserve Teams, Slack, Opsgenie, and all public inputs and outputs.
- FR-002: Defer package-existence evaluation until the producing operation completes.
- FR-003: Preserve Terraform/provider compatibility and deployed resource identities.
- FR-004: Add a regression with actual archive generation, a clean directory, and two instances without live AWS operations.
- FR-005: Deliver a reviewed fix PR through existing semantic-release; change consumer pins only after publication.

## Success Criteria

- SC-001: The clean-run regression fails before the fix and passes afterward.
- SC-002: Existing subscription tests and scoped validation pass.
- SC-003: No destination, public interface, or provider-major change is introduced.

## Assumptions and boundaries

The operator approved retaining Teams and preparing the shared fix and release. Cloud apply, routing-policy changes, and runtime modernization are outside scope. A failed production apply may be partial; review its next plan after publication.
