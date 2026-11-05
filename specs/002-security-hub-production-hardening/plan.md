# Implementation plan

## Current state and gaps

PR #108 uses one DynamoDB ledger and application-level Opsgenie aliases. Existing grouped delivery is opt-in and keeps per-finding mode. The 300-second digest timed out on a production ledger with hundreds of thousands of rows; a full scan every 15 minutes and daily full Security Hub reconciliation are unbounded for this volume. The router can act on an unaccepted stale event, and closure waits for routine findings. Inspector ECR use count is available through `inspector2:ListFindings`, but its ECS/EKS inventory is delayed and does not prove public exposure.

## Design

1. Add an optional, bounded Inspector lookup on relevant ECR events. Only positive, matching image-use evidence may mark an image as `observed_in_use`, distinct from verified current deployment; zero, absent, mismatched, or failed lookup remains unknown. Keep exposure and active exploitation independent. Add only the read permission required by the existing router.
2. Compare AWS snapshot fields before accepting equal-`UpdatedAt` writes. Allow equal-time policy and enrichment changes; never use an incoming event for routing after the ledger rejects it. Acknowledge daily delivery only if the exact ledger snapshot is still current. Preserve legacy-row migration.
3. Change incident transition logic to count currently paging-qualified active findings, apply the existing quiet period, clear prior P1 claim after a confirmed downgrade to P2, and retain routine findings for digest tracking.
4. Add focused unit tests and update the module README and optional Terraform input. Keep resource addresses and the existing grouped object interface stable.
5. Stress the existing scheduled worker with a large fake ledger and compare with post-apply CloudWatch evidence. Do not hide an unresolved capacity failure with a higher timeout or read filter that still consumes all DynamoDB reads.

## Compatibility and rollout

No resource moves or replacements are intended. The optional lookup input defaults to disabled because a central monitoring account may see member-account Security Hub findings without being able to retrieve the same findings through Inspector. Enabling it after access verification adds `inspector2:ListFindings` to the router role; lookup failure falls back to unknown, never to safe. Incident closure behavior changes after the quiet period and must be reviewed against Opsgenie ownership policy. A production plan and canary are required before applying. P2 paging depends on external Opsgenie team configuration. If the worker still cannot complete at the observed production volume, recommend REQUEST CHANGES and do not roll out.

## Governance

This is an extension of the existing module, so no new upstream module or wrapper selection applies. The current Terraform layout and grouped variable conventions remain. Shared module rules come from the local `terraform-module-developer` skill and constitution references. This package supplies the downstream Speckit evidence for module-impacting changes.
