output "topic_arn" {
  value = module.topic.arn
}

output "dead_letter_queue_name" {
  description = "Name of the SNS/Lambda dead-letter queue, if enabled."
  value       = try(module.dead_letter_queue[0].queue_name, null)
}

output "dead_letter_queue_arn" {
  description = "ARN of the SNS/Lambda dead-letter queue, if enabled."
  value       = try(module.dead_letter_queue[0].queue_arn, null)
}

output "slack_lambda_names" {
  description = "Slack notification Lambda function names, keyed by stable webhook instance key."
  value       = { for key, notifier in module.notify_slack : key => notifier.notify_slack_lambda_function_name }
}
