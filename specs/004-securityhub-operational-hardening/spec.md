# Security Hub grouped delivery hardening

## Problem

Grouped delivery currently invokes the immediate router for every imported finding, including routine severities that the scheduled digest already reconciles. The digest scans its ledger and reads each group marker every 15 minutes, even when a group cannot produce an Opsgenie action. An immediate urgent alert can also remain open if its finding clears before the first digest records `opsgenie_open`; routine updates can postpone closure of an established alert.

## Requirements

- Preserve the current module interface, per-finding mode, notification cutover, and daily Slack brief.
- In grouped mode, send active HIGH and CRITICAL imported findings to the immediate router. Reconcile routine and resolved findings through the scheduled digest.
- Avoid per-group state reads for groups with no urgent findings and no open or immediately sent Opsgenie alert. Do not skip a group that may need closure.
- Start a one-hour quiet period when a group has no urgent findings. Close its Opsgenie alert after that period, including an alert created by the immediate router before the first digest. Routine finding updates must not restart the quiet period.
- Keep alert creation, updates, and closure idempotent under repeated digest runs and eventual Opsgenie API responses.
- Keep delivery failure alarms and dead-letter handling intact.
- Alert through the existing independent failure topic when a grouped digest approaches its 300-second execution limit.

## Acceptance

- A grouped EventBridge plan filters immediate events to active HIGH/CRITICAL findings; per-finding mode retains resolution events.
- A routine group with no alert marker needs no per-group read or Opsgenie request during a digest.
- An urgent-only alert that clears before its first digest is closed after one quiet hour. An unrelated routine finding update does not delay closure. Repeated runs do not send a second close.
- Focused Python tests and Terraform validation pass. A plan for an existing consumer shows only the intended digest-duration alarm and routing/code updates, with no interface changes or unexpected replacements.
- A grouped consumer gets one digest-duration alarm before timeout; consumers without grouped delivery get none.

## Assumptions

- The 15-minute Security Hub reconciliation remains responsible for routine findings and resolution detection in grouped mode.
- Existing groups continue to use the same DynamoDB table and Opsgenie aliases.
