# Running image environment

## Why

Inspector ECR findings describe registry images, not the workload using them. Corify's shared ECR account has an `infra` repository tag even when an image runs in dev, stage, integration, pre-prod, or prod. Showing that tag as the deployment environment would be incorrect.

## Requirements

- The grouped Security Hub digest may read an optional, fresh inventory of running Kubernetes pod images.
- Match the complete ECR account, Region, repository, and SHA-256 digest. Include init containers.
- Show all matched workload environments in incident and Teams/Slack messages.
- Show `No running workload found` only when the inventory is complete and fresh; otherwise show `Unverified`.
- A display environment change must update an existing incident without changing its alias, remediation group, priority, or finding state.
- The inventory must be opt-in and must not affect existing consumers that omit it.

## Acceptance

- A digest present in dev and prod shows both environments.
- A digest absent from a complete fresh inventory shows `No running workload found`.
- Stale or incomplete inventory shows `Unverified`.
- An environment change updates the existing group description and mirror message once.
- Non-ECR findings and grouping remain unchanged.
