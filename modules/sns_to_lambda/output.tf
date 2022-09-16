output "sns_topic_arn" {
  value = module.topic.topic_arn
}

output "lambda_function_arn" {
  value = module.sns_to_servicenow.function_arn
}
