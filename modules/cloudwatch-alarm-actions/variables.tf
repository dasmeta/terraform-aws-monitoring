variable "topic_name" {
  type        = string
  description = "The SNS topic name"
  default     = "cloudwatch-alerts"
}

variable "create_topic" {
  type        = bool
  description = "Whether to create sns topic"
  default     = true
}

variable "delivery_policy" {
  type        = any
  description = "The SNS topic delivery policy"
  default = {
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  }
}

variable "email_addresses" {
  type        = list(string)
  default     = []
  description = "List of email addresses to send notification to"
}

variable "fallback_email_addresses" {
  type        = list(string)
  default     = []
  description = "List of fallback email addresses to send notification when lambda failed"
}

variable "phone_numbers" {
  type        = list(string)
  default     = []
  description = "List of international formatted phone number to send notification to"
}

variable "fallback_phone_numbers" {
  type        = list(string)
  default     = []
  description = "List of international formatted phone number to send notification when lambda failed"
}

variable "web_endpoints" {
  type        = list(string)
  default     = []
  description = "List of web webhooks endpoints (like opsgenie) to send notification to"
}

variable "fallback_web_endpoints" {
  type        = list(string)
  default     = []
  description = "List of web webhooks endpoints (like opsgenie) to send notification when lambda failed"
}

variable "slack_webhooks" {
  type = list(object({
    hook_url = string
    channel  = string
    username = string
  }))
  default     = []
  description = "List of slack webhook configs to send notification to"
}

variable "servicenow_webhooks" {
  type = list(object({
    domain = string
    path   = string
    user   = string
    pass   = string
  }))
  default     = []
  description = "List of servicenow webhook configs to send notification to"
}

variable "teams_webhooks" {
  type        = list(string)
  default     = []
  description = "Teams webhook configs to send notification to"
}

variable "log_group_retention_days" {
  type        = number
  default     = 7
  description = "The count of days that cloudwatch log group will keep each log item and then will cleanup automatically"
}

variable "enable_dead_letter_queue" {
  type        = bool
  default     = true
  description = "Whether to enable dead letter queue"
}

variable "recreate_missing_package" {
  type        = bool
  default     = true
  description = "Whether to recreate missing Lambda package if it is missing locally or not"
}

variable "log_level" {
  type        = string
  default     = "INFO"
  description = "log level for python code"
}

variable "lambda_failed_alert" {
  type = any
  default = {
    period    = 60
    threshold = 1
    equation  = "gte"
    statistic = "sum"
  }
  description = "Alert for lambda failed "
}
