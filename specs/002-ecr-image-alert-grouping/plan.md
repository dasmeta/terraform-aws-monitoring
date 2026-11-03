# Plan: Group Inspector ECR Image Alerts

## Current module and boundary

`modules/security-hub/functions/finding_router.py` in v3.1.0 groups Inspector EC2 nodes by cluster, pool, and AMI. Its fallback uses the finding key. `AwsEcrContainerImage` findings therefore create one group per CVE, even when their `Resources[0].Id` identifies the same immutable image. The existing wrapper, Terraform variables, providers, and resources remain in scope without interface changes.

## Design

Add a dedicated Inspector ECR case before the per-finding fallback. Form the group key from account, Region, product, and the full ECR resource ID, which includes repository and digest. Use repository and a short digest only for the human-facing label. If the ID does not identify an image digest, keep the current fallback. Preserve existing EC2 grouping and per-finding behavior elsewhere.

The urgent delivery path already deduplicates by group key and destination, so it needs no new AWS resources. Existing DynamoDB entries retain their original group identity; release operations must review and consolidate previously opened P1 alerts separately. Do not silently close real security findings.

## Files and validation

- Update `modules/security-hub/functions/finding_router.py`.
- Add focused Python tests under `modules/security-hub/tests/` for same/different ECR images, fallback, and urgent deduplication.
- Update `modules/security-hub/README.md` with ECR grouping and rollout behavior.
- Run Python tests, syntax checks, and targeted Terraform validation. Review the consumer plan after a tagged module release; no consumer version change is part of this module branch.

## Rollout and rollback

The Sela automated EventBridge rule is currently paused; manual routing remains enabled. Publish a patch release, pin the consumer to it, inspect a plan with no unexpected AWS resource changes, then re-enable automatic routing and watch alert count, router logs, and failure queues over the next representative Inspector scan. If distinct P1 alerts recur for one image, disable the automated rule again and investigate the grouping key.

## Speckit and standards

This repository has existing `specs/` packages but no `.specify` scripts. This package supplies the required spec, plan, and tasks in the repository's established layout. The change is confined to the existing module and has no new provider capability, wrapper input, or Terraform state migration. The active alert burst warrants preparing and testing the patch while production automation remains paused.
