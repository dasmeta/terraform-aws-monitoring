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
