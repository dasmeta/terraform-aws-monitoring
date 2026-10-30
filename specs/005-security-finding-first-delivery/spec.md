# Security finding first-delivery routing

## User outcome

After the production cutover, every newly discovered active Security Hub finding is sent to the dedicated SPM security Slack channel once. A HIGH or CRITICAL finding also reaches an Opsgenie AmazonSecurityHub integration. Subsequent updates to the same unresolved finding do not repeat Slack or Opsgenie delivery. Security Hub delivery-failure alarms go to the security channel, not the general monitoring channel.

## Scope and compatibility

- Preserve existing Security Hub and Inspector ownership, standards, manual SendNotification action, and existing finding SNS topic.
- Opt into the new routing mode explicitly so existing module consumers retain their current behavior.
- Use the finding's account, product ARN, and ID for a durable per-destination delivery record. A LOW/MEDIUM finding that later becomes HIGH/CRITICAL gets its first Opsgenie alert without repeating Slack.
- Store a UTC cutover timestamp at first apply to suppress alerts for findings created before the rollout. An explicit timestamp can be supplied for tests or controlled migration. Do not bulk-change existing Security Hub workflow statuses.
- Send all severity labels to the existing dedicated security Slack topic. Send HIGH/CRITICAL findings to a separate SNS topic subscribed to the AmazonSecurityHub Opsgenie endpoint.
- Route EventBridge, router, and subscription delivery failures to a distinct security escalation topic with the dedicated Slack webhook. Keep general account monitoring intact.
- Detect new SNS and Lambda failures even while a historical dead-letter queue backlog keeps its depth alarm in ALARM; retain old queue messages for investigation.
- A deliberate manual SendNotification action remains available as a manual override.

## Acceptance criteria

- Two updates for the same active finding produce one Slack publish. HIGH/CRITICAL produces one Opsgenie publish; a later severity escalation produces only the missing Opsgenie publish.
- Findings older than the cutover produce no automatic publishes.
- Concurrent updates use an atomic claim; failed publishes can be retried and are visible through delivery-failure alarms or queues.
- Fresh router, Slack Lambda, and SNS delivery errors have alarms that can change state independently of the historical queue backlog.
- The production plan contains no Security Hub alarm action pointing to `account-alarms-handling` and no finding topic subscription to the CloudWatch Opsgenie integration.
- A controlled test confirms Slack in the security channel and a HIGH/CRITICAL alert in Opsgenie before module review.
