output "topic_arn" {
  description = "ARN of the alert SNS topic."
  value       = module.topic.arn
}

output "opsgenie_guardduty_enrichment" {
  description = "Opsgenie GuardDuty enrichment Lambda outputs, or null when enrichment is disabled."
  value       = try(module.notify_opsgenie_guardduty[0], null)
}
