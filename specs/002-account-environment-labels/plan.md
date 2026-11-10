# Implementation plan

Add optional `finding_delivery.account_environment_labels` to the existing grouped input. Pass it to the router and digest Lambdas. Resolve the label from `AwsAccountId` before the static label. Keep the configured static label in existing ECR grouping hashes so an in-place rollout does not duplicate incidents. Relabel groups loaded from the ledger before building Slack and Opsgenie messages. Summarize mixed accounts and environments accurately. Update the module README and focused regression tests.

Add an optional list of environment labels whose CRITICAL non-container Inspector findings use P2. Its empty default preserves existing consumers. A consumer can include only Dev, so Root and Production retain P1. This changes Dev P1 incidents to P2 on reconciliation while retaining their aliases.

This is an additive interface change. Existing consumers with no map retain behavior. Terraform changes Lambda environment variables and code packages; it does not require new AWS resources or state moves. A downstream YAML consumer can map production, development, and root account IDs after consuming a released module version. A remote Terraform plan must be checked before apply. Rollback is a previous module version and prior YAML, with no ledger migration.

The repository has an existing `specs/` convention but no `.specify` bootstrap, so this package follows that convention directly. No additional module features are included.
