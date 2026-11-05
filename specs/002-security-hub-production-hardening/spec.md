# Security Hub production hardening

**Branch:** `fix/inspector-remediation-grouping`
**Baseline:** PR #108 at `3bd8d6e`
**Status:** Implementation requested, 2026-11-05

## Requirements

- Keep the existing Security Hub EventBridge, Lambda, DynamoDB, SNS, Slack, and Opsgenie architecture and Terraform addresses.
- Persist policy-only and verified-risk changes even when AWS `UpdatedAt` is unchanged. Reject older or conflicting same-timestamp AWS snapshots; use the accepted ledger record for delivery.
- Use reliable Inspector ECR image-use evidence where available; absent, zero, stale, or inaccessible evidence remains `unknown`. Exposure and active exploitation require separate evidence.
- Keep one application-level Opsgenie alias across CVEs and digests. Promote P2 to P1 when justified; update changed incident details without duplicate creates or notes.
- Close an incident after a quiet period when no active finding still qualifies for paging, even if routine findings remain in the digest. A new qualifying finding must be able to reopen or repromote it.
- GuardDuty port probes reach Slack once; only configured urgent types page. Duplicate and stale events do not suppress a new urgent finding.
- Measure reconciliation behavior at Inspector scale, preserve pagination and retries, and surface any capacity gap as a production blocker.
- State clearly that P2 is an Opsgenie incident and may page depending on external team routing.
- Preserve historical alert traceability and close old aliases only after a replacement incident or digest representation is confirmed.
- Do not merge, apply Terraform, or change production infrastructure in this task.

## Acceptance evidence

Python regression tests cover policy-only changes, stale events, deployment lookup, application incident lifecycle, GuardDuty routing, legacy migration, and large pagination. Terraform format, validate, and module tests run where tooling permits. Production readiness requires measured digest completion on a large production ledger and external verification of Opsgenie P2 routing.
