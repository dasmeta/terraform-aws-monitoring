# Plan

## Scope and evidence

- Downstream module: `modules/security-hub` in `terraform-aws-monitoring`.
- A live grouped deployment accumulated more than 6,000 findings and roughly 1,000 remediation groups shortly after its event rule was enabled. Most findings were below HIGH severity. Its digest currently reads every group marker even though only a few groups have a paging alert.
- This is a behavior-preserving optimization for grouped routing and a closure correctness fix. The only new resource is a grouped digest-duration alarm; no variable, output, existing state address, or provider constraint changes.
- CloudBrowser has a generic AWS Security Hub module record; it does not identify this Terraform module or store its implementation plan. This repository package is the authoritative change artifact.

## Design

1. Narrow only grouped-mode EventBridge imports to `ACTIVE`, workflow `NEW`/`NOTIFIED`, and severity `HIGH`/`CRITICAL`. Keep the broad per-finding API pattern so its resolution handler still receives closed events. The digest continues to fetch every recently updated finding for the daily brief.
2. Include group marker status in the existing consistent DynamoDB ledger scan. Skip per-group `GetItem` and Opsgenie sync when a group has no urgent findings and no open or immediate urgent marker. Keep a fresh read for groups that may page or close.
3. Track `opsgenie_no_urgent_since` on each group marker. Start it once when urgency clears; clear it if urgency returns. Close an open or immediately sent alert after one quiet hour, independently of routine updates. Treat a missing already-closed alias as a completed close.
4. Alarm on maximum digest duration at 240 seconds in a 15-minute period, using the existing delivery-failure topic. The current Lambda timeout remains 300 seconds.
5. Add focused tests for event filtering, skip behavior, immediate-alert closure, quiet-period stability, repeat-run idempotency, and the new alarm. Run Python tests, Terraform validation, and inspect the consumer plan before deployment.

## Risks and rollback

- Filtering routine EventBridge events means their first ledger appearance can be up to one digest interval later. Daily brief timing remains unchanged.
- A digest failure delays routine and closure reconciliation; existing Lambda and EventBridge failure alarms remain the detection path.
- Roll back by pinning the prior immutable module commit. The added marker field is ignored by the prior code.

## Standards and compatibility

- Existing DasMeta wrapper and grouped `finding_delivery` variable remain unchanged.
- The AWS EventBridge pattern uses existing provider-supported fields; no new provider capability or version floor is required.
- The source repository has `specs/` packages but no `.specify/` scaffold in this worktree, so this package follows the established spec/plan/tasks artifact layout without bootstrapping unrelated templates.
