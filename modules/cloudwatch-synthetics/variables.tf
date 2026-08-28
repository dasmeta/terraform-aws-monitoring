variable "name_prefix" {
  type        = string
  description = "Prefix for generated resource names."
}

variable "sns_topic_arn" {
  type        = string
  description = "Consumer-owned SNS topic ARN for canary failure alarms."

  validation {
    condition     = can(regex("^arn:aws:sns:", var.sns_topic_arn))
    error_message = "sns_topic_arn must be a valid SNS topic ARN."
  }
}

variable "canaries" {
  type = map(object({
    check_type   = string
    endpoint_url = string
    secret_arn   = string

    schedule        = optional(string, "rate(1 minute)")
    timeout_seconds = optional(number, 60)
    retries         = optional(number, 0)
    runtime_version = optional(string, "syn-python-selenium-11.1")
    secret_fields   = optional(map(string), {})
    environment     = optional(map(string), {})
    tags            = optional(map(string), {})

    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))

    alarm_config = optional(object({
      enabled             = optional(bool, true)
      threshold           = optional(number, 1)
      evaluation_periods  = optional(number, 1)
      datapoints_to_alarm = optional(number, 1)
      period              = optional(number, 60)
      treat_missing_data  = optional(string, "breaching")
      comparison_operator = optional(string, "LessThanThreshold")
    }))
  }))

  description = "Map of canary configurations keyed by stable logical name."

  validation {
    condition     = length(var.canaries) > 0
    error_message = "canaries map must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : contains([
        "soap_wsdl",
        "soap_cardinfo",
        "rest_cardinfo",
        "blackhawk_management",
      ], c.check_type)
    ])
    error_message = "Each canary check_type must be one of: soap_wsdl, soap_cardinfo, rest_cardinfo, blackhawk_management."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : can(regex("^(rate\\([0-9]+ (minute|minutes|hour|hours|day|days)\\)|cron\\(.+\\))$", c.schedule))
    ])
    error_message = "Each canary schedule must be a valid rate(...) or cron(...) expression."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : c.timeout_seconds >= 3 && c.timeout_seconds <= 840
    ])
    error_message = "Each canary timeout_seconds must be between 3 and 840."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : can(regex("^arn:aws:secretsmanager:", c.secret_arn))
    ])
    error_message = "Each canary secret_arn must be a valid Secrets Manager ARN."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : c.retries >= 0 && c.retries <= 2
    ])
    error_message = "Each canary retries must be between 0 and 2."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries : can(regex("^syn-python(-selenium-[0-9]+(\\.[0-9]+)?|-[0-9]+(\\.[0-9]+)?)$", c.runtime_version))
    ])
    error_message = "Each canary runtime_version must match syn-python-selenium-* or syn-python-*."
  }

  validation {
    condition = alltrue([
      for k, c in var.canaries :
      c.vpc_config == null || (
        length(c.vpc_config.subnet_ids) > 0 && length(c.vpc_config.security_group_ids) > 0
      )
    ])
    error_message = "When vpc_config is set, both subnet_ids and security_group_ids are required and must be non-empty."
  }
}

variable "create_artifact_bucket" {
  type        = bool
  default     = true
  description = "Whether to create a module-managed S3 bucket for canary artifacts and script bundles."
}

variable "artifact_bucket_name" {
  type        = string
  default     = null
  description = "Name of an existing S3 bucket for artifacts when create_artifact_bucket is false."

  validation {
    condition     = var.create_artifact_bucket || (var.artifact_bucket_name != null && var.artifact_bucket_name != "")
    error_message = "artifact_bucket_name is required when create_artifact_bucket is false."
  }
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for S3 SSE-KMS encryption and Secrets Manager decrypt."

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN when set."
  }
}

variable "log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch log retention in days for canary log groups."
}

variable "artifact_expiration_days" {
  type        = number
  default     = 30
  description = "S3 lifecycle expiration in days for canary artifact objects."
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all taggable module resources."
}
