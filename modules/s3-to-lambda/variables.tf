variable "name" {
  type        = string
  description = "Lambda name"
}

variable "bucket_name" {
  type        = list(string)
  description = "S3 bucket for s3 subscription"
}

variable "lambda_configs" {
  type = object({
    environment_variables = optional(object({
      url = optional(string, "")
    }), {})
  })
  default     = {}
  description = "Lambda Configs"
}
