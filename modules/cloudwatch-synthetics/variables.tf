variable "name_prefix" {
  type        = string
  description = "Prefix for generated resource names."

  validation {
    condition     = length(trim(replace(lower(var.name_prefix), "/[^a-z0-9-]/", ""), "-")) > 0
    error_message = "name_prefix must contain at least one letter or number after sanitization."
  }
}

variable "sns_topic_arn" {
  type        = string
  description = "Consumer-owned SNS topic ARN for canary failure alarms."

  validation {
    condition     = can(regex("^arn:[^:]+:sns:[^:]+:[0-9]{12}:.+", var.sns_topic_arn))
    error_message = "sns_topic_arn must be a valid SNS topic ARN."
  }
}

variable "canaries" {
  type = map(object({
    script_zip_path = string
    secret_arn      = string

    schedule        = optional(string, "rate(5 minutes)")
    timeout_seconds = optional(number, 60)
    runtime_version = optional(string, "syn-python-selenium-11.1")
    tags            = optional(map(string), {})

    vpc_config = optional(object({
      subnet_ids         = list(string)
      security_group_ids = list(string)
    }))

    alarm_config = optional(object({
      enabled             = optional(bool, true)
      evaluation_periods  = optional(number, 1)
      datapoints_to_alarm = optional(number, 1)
      period              = optional(number, 60)
      treat_missing_data  = optional(string, "notBreaching")
    }), {})
  }))

  description = "Map of generic consumer ZIP canary configurations keyed by stable logical name."

  validation {
    condition     = length(var.canaries) > 0
    error_message = "canaries map must contain at least one entry."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      can(regex("^(rate\\([0-9]+ (minute|minutes|hour|hours|day|days)\\)|cron\\(.+\\))$", cfg.schedule))
    ])
    error_message = "Each canary schedule must be a valid rate(...) or cron(...) expression."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : cfg.timeout_seconds >= 3 && cfg.timeout_seconds <= 840
    ])
    error_message = "Each canary timeout_seconds must be between 3 and 840."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      can(regex("^arn:[^:]+:secretsmanager:[^:]+:[0-9]{12}:secret:.+", cfg.secret_arn))
    ])
    error_message = "Each canary secret_arn must be a valid Secrets Manager ARN."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : fileexists(cfg.script_zip_path)
    ])
    error_message = "Each canary script_zip_path must point to an existing ZIP archive."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      can(regex("^syn-python(-selenium-[0-9]+(\\.[0-9]+)?|-[0-9]+(\\.[0-9]+)?)$", cfg.runtime_version))
    ])
    error_message = "Each canary runtime_version must match syn-python-selenium-* or syn-python-*."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      cfg.vpc_config == null || (length(cfg.vpc_config.subnet_ids) > 0 && length(cfg.vpc_config.security_group_ids) > 0)
    ])
    error_message = "When vpc_config is set, subnet_ids and security_group_ids must both be non-empty."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : length(replace(lower(key), "/[^a-z0-9-]/", "")) > 0
    ])
    error_message = "Each canary map key must contain at least one letter, number, or hyphen."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      cfg.alarm_config.evaluation_periods >= 1 &&
      cfg.alarm_config.datapoints_to_alarm >= 1 &&
      cfg.alarm_config.datapoints_to_alarm <= cfg.alarm_config.evaluation_periods &&
      cfg.alarm_config.period > 0 &&
      contains(["breaching", "notBreaching", "ignore", "missing"], cfg.alarm_config.treat_missing_data)
    ])
    error_message = "Each alarm_config must use valid positive values and a valid missing-data treatment."
  }
}

variable "create_artifact_bucket" {
  type        = bool
  default     = true
  description = "Whether to create a module-managed S3 bucket for canary artifacts and consumer ZIPs."
}

variable "artifact_bucket_name" {
  type        = string
  default     = null
  description = "Name of a consumer-owned artifact bucket when create_artifact_bucket is false."
}

variable "artifact_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform may delete module-created versioned artifacts; use only for isolated tests."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for artifact encryption and secret decryption."

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN when set."
  }
}

variable "artifact_expiration_days" {
  type        = number
  default     = 30
  description = "Days to retain current and noncurrent artifact objects."

  validation {
    condition     = var.artifact_expiration_days >= 1
    error_message = "artifact_expiration_days must be at least one."
  }
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all taggable module resources."
}
