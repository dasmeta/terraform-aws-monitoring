output "canary_arns" {
  description = "Map of canary key to Synthetics canary ARN."
  value       = { for key, canary in aws_synthetics_canary.this : key => canary.arn }
}

output "canary_names" {
  description = "Map of canary key to resolved Synthetics canary name."
  value       = { for key, canary in aws_synthetics_canary.this : key => canary.name }
}

output "execution_role_arns" {
  description = "Map of canary key to execution IAM role ARN."
  value       = { for key, role in aws_iam_role.canary : key => role.arn }
}

output "alarm_arns" {
  description = "Map of canary key to enabled CloudWatch alarm ARN."
  value       = { for key, alarm in aws_cloudwatch_metric_alarm.canary_failed : key => alarm.arn }
}

output "artifact_bucket_arn" {
  description = "ARN of the selected artifact S3 bucket."
  value       = local.artifact_bucket_arn
}

output "script_object_keys" {
  description = "Map of canary key to uploaded module-built source package object key."
  value       = { for key, bundle in aws_s3_object.canary_bundle : key => bundle.key }
}

output "script_object_version_ids" {
  description = "Map of canary key to uploaded module-built source package object version ID."
  value       = { for key, bundle in aws_s3_object.canary_bundle : key => bundle.version_id }
}
