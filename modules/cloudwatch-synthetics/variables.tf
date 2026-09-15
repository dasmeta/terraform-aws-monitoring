variable "name_prefix" {
  type        = string
  description = "Prefix for generated resource names."

  validation {
    condition     = length(trim(replace(lower(var.name_prefix), "/[^a-z0-9-]/", ""), "-")) > 0
    error_message = "name_prefix must contain at least one letter or number after sanitization."
  }
}

variable "sns_topic_name" {
  type        = string
  description = "Existing SNS topic name for canary failure alarms."

  validation {
    condition     = trimspace(var.sns_topic_name) != "" && !startswith(trimspace(var.sns_topic_name), "arn:")
    error_message = "sns_topic_name must be a non-empty SNS topic name, not an ARN."
  }
}

variable "canaries" {
  type = map(object({
    source_files = map(string)
    secret_name  = optional(string)
    config       = optional(map(string), {})

    schedule        = optional(string, "rate(5 minutes)")
    timeout_seconds = optional(number, 60)
    memory_in_mb    = optional(number, 960)
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

  description = "Map of generic canary configurations keyed by stable logical name. Source files are relative to the consumer Terraform root; source symlinks are unsupported. secret_name is optional when the canary does not read Secrets Manager. memory_in_mb must be 960-3008 and a multiple of 64."

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
      cfg.secret_name == null || (
        trimspace(cfg.secret_name) != "" &&
        !startswith(trimspace(cfg.secret_name), "arn:")
      )
    ])
    error_message = "Each canary secret_name, when set, must be a non-empty Secrets Manager secret name, not an ARN."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries :
      cfg.memory_in_mb >= 960 && cfg.memory_in_mb <= 3008 && cfg.memory_in_mb % 64 == 0
    ])
    error_message = "Each canary memory_in_mb must be between 960 and 3008 and a multiple of 64."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : length(cfg.source_files) > 0 && contains(keys(cfg.source_files), "python/canary.py")
    ])
    error_message = "Each canary source_files map must be non-empty and include python/canary.py."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : alltrue([
        for destination, source_path in cfg.source_files :
        can(regex("^python/[A-Za-z0-9][A-Za-z0-9._/-]*$", destination)) &&
        !endswith(destination, "/") &&
        length(regexall("//", destination)) == 0 &&
        length(regexall("\\.\\.", destination)) == 0 &&
        !contains(split("/", destination), ".") &&
        trimspace(source_path) != "" &&
        !startswith(source_path, "/") &&
        !endswith(source_path, "/") &&
        length(regexall("//", source_path)) == 0 &&
        !contains(split("/", source_path), ".") &&
        !contains(split("/", source_path), "..")
      ])
    ])
    error_message = "Each source_files destination must be a canonical python/... path, and each source path must be a non-empty relative path without traversal segments."
  }

  validation {
    condition = alltrue([
      for key, cfg in var.canaries : !contains(keys(cfg.config), "secret_name")
    ])
    error_message = "Each canary config map must not set secret_name; the module generates that field."
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
  description = "Whether to create a module-managed S3 bucket. When true, artifact_bucket_name optionally overrides the generated name. When false, artifact_bucket_name is required."
}

variable "artifact_bucket_name" {
  type        = string
  default     = null
  description = "Artifact bucket name. Overrides the generated name when create_artifact_bucket is true; names the existing bucket when create_artifact_bucket is false."
}

variable "artifact_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Whether Terraform may delete module-created versioned artifacts; use only for isolated tests."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for artifact bucket encryption."

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:[^:]+:kms:[^:]+:[0-9]{12}:key/.+", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid KMS key ARN when set."
  }
}

variable "artifact_expiration_days" {
  type        = number
  default     = 30
  description = "Days to retain current and noncurrent canary run artifacts under the canaries/ prefix. Source packages under scripts/ are not expired."

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
