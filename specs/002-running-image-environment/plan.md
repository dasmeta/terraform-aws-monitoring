# Plan

The module currently derives `environment` only from a global setting or Security Hub resource tags. Neither identifies the running workload for a shared ECR image. Keep that existing field for grouping and paging, and add a separate display environment resolved from a short-lived S3 snapshot at notification time.

Add one optional grouped `deployment_inventory` input containing bucket, key, maximum age, and expected cluster names. Give the digest Lambda read access to that object only. Validate snapshot freshness, coverage, and image identity before using it. Apply the display value to grouped incident descriptions and SNS mirror payloads, and persist the last displayed value to trigger an update when it changes.

The Corify consumer owns the S3 bucket and GitLab OIDC publisher role. The Kubernetes repository publishes a complete snapshot of running pod and init-container image IDs from both clusters. No state address changes or breaking inputs are needed. Existing examples and Python tests will cover enabled and omitted input cases. Production rollout follows the upstream module release, consumer plan, and inventory job schedule.
