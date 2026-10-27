# Data model

The existing automatic EventBridge rule filters current findings by severity, record state, and workflow state. The existing manual rule filters custom actions by the module's action target.

When notification actions are enabled, both SNS targets use a standard SQS failure queue for retry-exhaustion records. The queue policy permits `sqs:SendMessage` from the two exact rule ARNs in the active account. The outputs expose queue ARN/URL and both rule ARNs so an operator can inspect failures.
