variable "name" {
  type        = string
  description = "Lambda name"
}

variable "cloudwatch_log_group_names" {
  type        = list(string)
  description = "Cloudwatch Log group name"
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
