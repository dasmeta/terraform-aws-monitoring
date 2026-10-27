# Implementation Plan: Security Hub alert lifecycle and delivery evidence

**Branch**: `003-cspm-alerting-remediation` | **Date**: 2026-10-27 | **Spec**: [spec.md](spec.md)

## Summary

Preserve the Security Hub monitoring submodule interface and existing EventBridge rule addresses. Filter automatic critical/high notifications to active, unresolved findings. Attach a retry policy and exact-rule SQS dead-letter queue to each enabled SNS target, and expose the route identifiers. This is a reusable monitoring wrapper improvement, with no corrective resource mutation in this repository.

## Technical Context

- **Language/Version**: Terraform `~> 1.3`; AWS provider `>= 5.0, < 7.0`.
- **Primary Dependencies**: Existing `cloudwatch-alarm-actions` and Security Hub submodules; AWS EventBridge, SNS, SQS.
- **Storage**: Optional route-level SQS delivery failure queue when notification actions are enabled.
- **Testing**: `terraform fmt`, `terraform init -backend=false`, `terraform validate`, `terraform test` on Terraform >= 1.6.
- **Target Platform**: Approved AWS account and Region; no live apply.
- **Project Type**: Reusable Terraform module.
- **Constraints**: Preserve resource addresses and input names; do not silently expand to the entire upstream module; keep queue permissions bound to specific rules.
- **Scale/Scope**: One automatic and one manual finding target per enabled module instance.

## Constitution Check

- Shared source: `infra-governance` PR #94 and the Terraform module developer internal standards; package is in this downstream repository before code edits.
- Existing `versions.tf` layout and `~> 1.3` contract stay unchanged. Existing opinionated wrapper is preserved. No grouped interface refactor, provider bump, or destructive state move is planned.
- New EventBridge target retry/DLQ is **supported** by [AWS guidance](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rule-dlq.html) and [provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) within the existing provider range.
- No breaking or interface-widening approval gate is triggered. Added queue is an enabled-alerting safety resource, and current rule addresses stay stable.
- Baseline gaps: the repository uses existing module-local tests and examples; a native test is added at the touched module surface. No repo-wide automation or release workflow changes are in scope.
- CloudBrowser: no exact monitoring documentation or linked repository module record matched this change. The account module catalog record `aws-account` was completed separately with its source repository link and scoped description.

## Phase 0 Research

See [research.md](research.md). Security Hub imported finding events include new and updated findings. AWS supports filtering at `detail.findings.Workflow.Status`. EventBridge DLQ catches failure to invoke SNS; it does not prove subscriber delivery or operator acknowledgement.

## Phase 1 Design

See [data-model.md](data-model.md), [contracts/alert-route.md](contracts/alert-route.md), and [quickstart.md](quickstart.md).

## Project Structure

```text
modules/security-hub/eventbridge.tf
modules/security-hub/outputs.tf
modules/security-hub/README.md
modules/security-hub/tests/cspm_alerting.tftest.hcl
specs/003-security-hub-cspm-alerting/
```

## Deployment and rollback

Review plans for the additional queue and rule pattern update. Confirm the approved home Region and target SNS ownership. Roll back by reverting the module release pin after checking the DLQ for pending failures; retained queue contents must be handled under the account's evidence policy.

## Verification and residual evidence

Use format, init, validate, native test, and `git diff --check`. A new immutable monitoring tag must exist before the account wrapper can adopt these improvements. Live delivery receipt, acknowledgement, escalation, estate coverage, and actual corrective execution remain separate evidence.

PR #98 (`002-selective-security-alerts`) is open and adds native GuardDuty, Inspector, and Macie SNS targets in this submodule. Its branch is behind current `main` and has an unrelated Checkov workflow conflict when stacked. Before either change is released with the other, extend the same retry, DLQ, and policy treatment to the service targets and rerun the selective-alert tests. This feature branch stays based on current `main` so the review isolates its changes.
