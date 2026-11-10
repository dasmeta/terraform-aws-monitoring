# Plan

Add an optional grouped `deployment_inventory` input with S3 bucket, key, freshness, and required cluster list. Grant the digest Lambda read access to that object only when configured. Load and validate one bounded snapshot per reconciliation, then resolve running environments for Inspector ECR group summaries. Keep source-account environment and incident identity separate from the running workload display. Cover exact matching, missing and stale snapshots, and existing incident updates in tests.

Review follow-up: document a valid snapshot with UTC timestamp, exact cluster coverage, lowercase environment labels, and all image identity fields. Add optional `kms_key_arn` and a key-scoped `kms:Decrypt` statement for SSE-KMS snapshots; leave IAM unchanged when it is unset. Cross-account key policies must also allow the digest role.

The consumer owns snapshot publication, S3, and schedule. The module adds no S3 bucket or writer. A consumer plan must review the digest Lambda environment variable and IAM policy update. Rollback is removal of the optional input or a prior module release.
