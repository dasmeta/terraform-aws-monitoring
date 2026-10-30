output "topic_arn" {
  value = module.topic.arn
}

output "dead_letter_queue_name" {
  description = "Name of the SNS/Lambda dead-letter queue, if enabled."
  value       = try(module.dead_letter_queue[0].queue_name, null)
}
