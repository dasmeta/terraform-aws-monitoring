# Plan

## Design

Add an opt-in Security Hub finding router Lambda and DynamoDB delivery table. EventBridge forwards active imported findings to the router. An SSM parameter records the first apply's UTC cutover time unless an explicit value is supplied. The router excludes older findings, claims per-finding Slack and Opsgenie destinations with conditional DynamoDB updates, publishes the original Security Hub event to the existing Slack SNS topic and a new HIGH/CRITICAL Opsgenie SNS topic, then records successful publishes. It does not change Security Hub workflow status. A new security-only SNS topic receives delivery-failure alarms and uses the dedicated security Slack webhook.

The existing manual action still publishes directly to the finding SNS topic. Existing module behavior remains the default unless the new routing input is enabled.

## Verification and rollout

Test the router with mocked SNS/DynamoDB clients for first delivery, repeat updates, severity escalation, cutoff, and retry behavior. Validate Terraform event rules, IAM, SNS policies, and generated SPM files. Use the current production state for a reviewable HCP plan. Apply only after the user's production approval, then send controlled synthetic LOW and HIGH notifications, verify Slack/Opsgenie and delivery queues, and keep PRs draft until the live checks pass.

The Opsgenie integration API does not return existing endpoint keys. Obtain an endpoint through a new scoped integration or the Opsgenie UI and store it in the root `account` secret without exposing it in Git or PR text. Refresh the root HCP output before planning SPM.
