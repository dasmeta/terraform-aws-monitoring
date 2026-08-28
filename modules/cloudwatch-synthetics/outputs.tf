output "canary_arns" {
  description = "Map of canary key to Synthetics canary ARN."
  value       = { for key, canary in aws_synthetics_canary.this : key => canary.arn }
}

output "canary_names" {
  description = "Map of canary key to AWS canary name."
  value       = { for key, canary in aws_synthetics_canary.this : key => canary.name }
}

output "alarm_arns" {
  description = "Map of canary key to CloudWatch alarm ARN."
  value       = { for key, alarm in aws_cloudwatch_metric_alarm.canary_failed : key => alarm.arn }
}

output "artifact_bucket_arn" {
  description = "ARN of the artifact S3 bucket."
  value       = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].arn : "arn:aws:s3:::${var.artifact_bucket_name}"
}

output "execution_role_arns" {
  description = "Map of canary key to IAM execution role ARN."
  value       = { for key, role in aws_iam_role.canary : key => role.arn }
}
