output "security_hub_account_id" {
  description = "The ID of the Security Hub account"
  value       = var.enable_security_hub ? aws_securityhub_account.sec-hub[0].id : null
}

output "security_hub_finding_aggregator_id" {
  description = "The ID of the Security Hub finding aggregator"
  value       = var.enable_security_hub_finding_aggregator ? aws_securityhub_finding_aggregator.sec-hub-aggregator[0].id : null
}

output "security_hub_action_target_arn" {
  description = "The ARN of the Security Hub action target"
  value       = aws_securityhub_action_target.sec-hub-target.arn
}

output "eventbridge_rule_arn" {
  description = "The ARN of the EventBridge rule for Security Hub findings"
  value       = aws_cloudwatch_event_rule.automated_alerts.arn
}

output "manual_eventbridge_rule_arn" {
  description = "ARN of the manual Security Hub custom-action rule when notification actions are enabled"
  value       = var.alarm_actions.enabled ? aws_cloudwatch_event_rule.manual_alerts[0].arn : null
}

output "eventbridge_failed_delivery_queue_arn" {
  description = "ARN of the queue that retains failed Security Hub EventBridge-to-SNS target invocations"
  value       = var.alarm_actions.enabled ? aws_sqs_queue.eventbridge_failed_delivery[0].arn : null
}

output "eventbridge_failed_delivery_queue_url" {
  description = "URL of the queue that retains failed Security Hub EventBridge-to-SNS target invocations"
  value       = var.alarm_actions.enabled ? aws_sqs_queue.eventbridge_failed_delivery[0].url : null
}

output "eventbridge_failed_delivery_alarm_arns" {
  description = "CloudWatch queue-depth and per-rule EventBridge DLQ alarm ARNs"
  value = var.alarm_actions.enabled ? merge(
    { queue_nonempty = aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].arn },
    { for key, alarm in aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric : key => alarm.arn }
  ) : {}
}

output "delivery_failure_response" {
  description = "Owner, escalation topic, and drain/replay runbook for Security Hub alert delivery failures"
  value       = var.alarm_actions.enabled ? var.delivery_failure : null
}

output "alarm_actions" {
  description = "CloudWatch Alarm Actions module outputs for Security Hub findings notifications. Note: Module can be enabled independently, but output is null when Security Hub is disabled for backward compatibility."
  value       = var.enable_security_hub && var.alarm_actions.enabled ? module.alarm_actions[0] : null
}

output "config" {
  description = "AWS Config module outputs. Note: Module can be enabled independently, but output is null when Security Hub is disabled for backward compatibility."
  value       = var.enable_security_hub && var.config.enabled ? module.config[0] : null
}

output "inspector" {
  description = "AWS Inspector module outputs. Note: Module can be enabled independently, but output is null when Security Hub is disabled for backward compatibility."
  value       = var.enable_security_hub && var.inspector.enabled ? module.inspector[0] : null
}

output "guardduty" {
  description = "AWS GuardDuty module outputs. Note: Module can be enabled independently, but output is null when Security Hub is disabled for backward compatibility."
  value       = var.enable_security_hub && var.guardduty.enabled ? module.guardduty[0] : null
}

output "macie" {
  description = "Amazon Macie module outputs. Note: Module can be enabled independently, but output is null when Security Hub is disabled for backward compatibility."
  value       = var.enable_security_hub && var.macie.enabled ? module.macie[0] : null
}

output "standards_subscriptions" {
  description = "Map of enabled Security Hub standards subscriptions (key is standard identifier, value is the subscription resource)"
  value       = var.enable_security_hub ? aws_securityhub_standards_subscription.standards : {}
}
