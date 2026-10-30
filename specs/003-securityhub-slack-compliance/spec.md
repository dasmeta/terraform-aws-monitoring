# Security Hub Slack findings without Compliance

## Problem

The production Security Hub Slack Lambda throws `KeyError: 'Compliance'` when an imported finding lacks the optional `Compliance` object. SNS accepts the event, but the Lambda fails and can place it in its dead-letter queue. This was observed after SPM production run `run-PNh5fjer46CbHL9A` on 2026-10-30.

## Scope

In `modules/cloudwatch-alarm-actions`, keep the existing SNS and Lambda resource addresses and the sensitive webhook handling from PR #106. Supply a patched source file to the pinned notify-slack module. Treat absent `Compliance` as `UNKNOWN` while preserving the status update for findings whose compliance status is `FAILED` and workflow status is `NEW`.

## Acceptance criteria

- Inspector and Security Hub findings without `Compliance` produce a Slack attachment instead of an exception.
- Findings with `Compliance.Status = FAILED` and `Workflow.Status = NEW` retain the existing `NOTIFIED` update behavior.
- The Terraform module initializes and validates with the source override, and the Lambda package can be built from a clean checkout.
- Existing SNS topic, subscription, Lambda, permission, and queue addresses remain stable.
- No production apply or test notification is part of this code change.
