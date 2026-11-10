# Implementation Plan: GuardDuty Alert Action Text

**Branch**: `fix/guardduty-alert-action` | **Date**: 2026-11-10 | **Spec**: `spec.md`

## Summary

Make GuardDuty action selection precede generic EC2 image patch selection, and use investigation guidance in grouped GuardDuty descriptions. Keep Inspector actions and routing unchanged.

## Technical Context

- Existing Terraform module: `modules/security-hub` in `terraform-aws-monitoring`.
- Runtime: Python 3.12 Lambda helpers packaged by the module.
- Source: `functions/group_alert_format.py` and `functions/group_digest.py`.
- Verification: existing `unittest` suite in `modules/security-hub/tests`.
- No Terraform variable, output, provider, resource, or state change.

## Constitution and Module Check

- The repository had `specs/` but lacked `.specify/`; Spec Kit was bootstrapped locally before this package. The package supplies `spec.md`, `plan.md`, and `tasks.md` for the module-change gate.
- Existing module remains an opinionated wrapper; no consumer interface widening or breaking change.
- This is an improve-mode formatter bugfix. No new provider capability is introduced; upstream module sourcing and template fallback do not apply.
- No conflict with the current module layout or the shared module-development standards was found.
- Existing tests and runtime helpers are the relevant verification surface; Terraform validation cannot exercise alert text.

## Design

1. Check GuardDuty identity before EC2 image metadata in shared alert action selection.
2. Give grouped GuardDuty descriptions investigation language while retaining the existing text for other products.
3. Add a regression case using GuardDuty EC2 metadata that reproduces the Sela alert, plus an Inspector preservation assertion.
4. Update the security-hub README only if it currently states GuardDuty alerts should recommend image patching.

## Risks and Validation

- Risk: Other products lose patch guidance. Mitigation: run existing Inspector action tests and assert the previous node image action.
- Risk: Immediate and digest paths diverge. Mitigation: test both paths against the same GuardDuty group.
- Validate targeted formatter tests, then the security-hub Python test suite; run `git diff --check`.
- No AWS deployment occurs from this source change. The released module must be adopted by consumers before runtime behavior changes.

## Files in Scope

- `modules/security-hub/functions/group_alert_format.py`
- `modules/security-hub/functions/group_digest.py`
- `modules/security-hub/tests/test_finding_grouping.py`
- `specs/002-guardduty-action-text/`
