variable "s3_bucket" {
  type        = string
  description = "S3 bucket name"
}

variable "lambda_function_arn" {
  type        = string
  description = "Lambda Function arn"
}

variable "sns_topic_arn" {
  type        = string
  description = "SNS Topic ARN"
}

variable "role_name" {
  type        = string
  description = "Lambda role name for attach police"
}
