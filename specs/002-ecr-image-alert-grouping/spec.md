# Feature Specification: Group Inspector ECR Image Alerts

**Feature Branch**: `004-ecr-image-alert-grouping`
**Created**: 2026-11-03
**Status**: Ready for implementation
**Input**: Production Security Hub routing opened separate P1 Opsgenie alerts for multiple Inspector CVEs on one ECR image digest.

## User Story 1: One remediation target, one urgent group (P1)

As an on-call operator, I need Inspector findings for the same ECR repository image digest to share one group, so a vulnerability burst produces one urgent Opsgenie alert and one immediate Slack notice for that image.

**Acceptance scenarios**

1. Different finding IDs for the same account, Region, repository, and digest have the same group key.
2. A different digest, repository, account, or Region has a different group key.
3. Repeated urgent findings in one image group publish only once per urgent destination.
4. A missing ECR image identity retains per-finding grouping instead of merging unrelated images.

## User Story 2: Preserve established routing (P1)

EC2/Karpenter grouping and non-ECR fallback grouping keep their current keys. The module interface and delivery resources do not change.

## User Story 3: Safe rollout (P1)

The module documentation explains ECR grouping and its effect on existing alerts. An operator can keep automated routing paused until a tagged release is deployed and its plan is reviewed. Existing P1 alerts are not silently closed by this code change.

## Evidence

At 2026-11-03 09:29–09:32 UTC, one `sela-backend` ECR image digest in account `515966492915`, Region `us-east-2`, produced multiple Inspector findings and separate grouped P1 alerts. The v3.1.0 router uses the finding hash for all non-EC2 resources, so each ECR CVE receives a unique group key. The Sela automated EventBridge rule was temporarily disabled to stop duplicate paging; the manual action stayed enabled.
