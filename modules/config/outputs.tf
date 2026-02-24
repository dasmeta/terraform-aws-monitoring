output "configuration_recorder_name" {
  description = "The name of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.this.name
}

output "configuration_recorder_id" {
  description = "The ID of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.this.id
}

output "delivery_channel_name" {
  description = "The name of the AWS Config delivery channel"
  value       = aws_config_delivery_channel.this.name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket used for AWS Config"
  value       = var.s3_bucket_name != "" ? var.s3_bucket_name : aws_s3_bucket.config[0].bucket
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for AWS Config"
  value       = var.s3_bucket_name != "" ? null : aws_s3_bucket.config[0].arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM service-linked role for AWS Config (AWSServiceRoleForConfig)"
  value       = local.config_service_linked_role_arn
}

output "service_linked_role" {
  description = "The AWS Config service-linked role resource (null if using existing role)"
  value       = var.create_service_linked_role ? aws_iam_service_linked_role.config[0] : null
}

output "rules" {
  description = "Map of Config rule resources (key is rule name)"
  value       = aws_config_config_rule.this
}
