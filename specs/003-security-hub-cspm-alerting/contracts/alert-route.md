# Alert route contract

The current `alarm_actions.enabled` input continues to own notification routing. When true, the module provides automatic and manual SNS targets with retries and a queue for target invocation failures. When false, there are no SNS targets and no queue. The automatic pattern matches ACTIVE CRITICAL/HIGH NEW/NOTIFIED findings. The manual custom-action pattern remains tied to the configured action target.

The new output identifiers are safe to publish; they contain no subscriber secrets or finding bodies. A queue record means EventBridge could not invoke SNS, not that a human acknowledged an alert. Operators must inspect SNS subscription delivery and response records separately.
