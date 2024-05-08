variable "sns_topic" {
  type        = string
  default     = "cloudwatch-alerts"
  description = "The name of aws sns topic use as target for alarm actions"
}

variable "alerts" {
  type = list(object({
    name               = string
    source             = string
    filters            = map(any)
    description        = optional(string, null)
    evaluation_periods = optional(number, 1)
    statistic          = optional(string, "sum")
    equation           = optional(string, "gte")
    threshold          = optional(number, 1)
    period             = optional(number, 300)
    treat_missing_data = optional(string, null)
    log_based_metric   = optional(bool, false)
    anomaly_detection  = optional(bool, false)
    account_id         = optional(string, null)
  }))

  description = "Allows to create standard and log based metric alarms"
  default     = []
}

# IMPORTANT: only us-east-1 (Virginia) region aws provider works with health_checks, so pleas have provider and create SNS topic in this region
variable "health_checks" {
  description = "Specifies the name of the Amazon SNS topic defined for notification of log file delivery"
  type = list(object({
    host : string
    port : optional(number, 443)
    path : optional(string, "/")
    type : optional(string, "HTTPS")
    measure_latency : optional(bool)
    regions : optional(list(string))
    tags : optional(map(string))
    main : optional(object({
      statistic : optional(string, "min")
      equation : optional(string, "lt")
      threshold : optional(number, 1)
      period : optional(number, "60")
    }))
    percentage : optional(object({
      statistic : optional(string, "avg")
      equation : optional(string, "lt")
      threshold : optional(number, 75)
      period : optional(number, 60)
    }))
  }))
  default = []
}

# @todo refactor to get topic from ouside but also have default value
# variable "sns_topic_name" {
#   type        = string
#   description = "Specifies the name of the Amazon SNS topic defined for notification of log file delivery"
#   default     = null
# }

variable "enable_insufficient_data_actions" {
  type        = bool
  default     = true
  description = "Enable insufficient data actions alert"
}

variable "enable_ok_actions" {
  type        = bool
  default     = true
  description = "Enable ok actions alert"
}

variable "enable_alarm_actions" {
  type        = bool
  default     = true
  description = "Enable alarm actions alert"
}

variable "expression_alert" {
  type        = any
  default     = {}
  description = "Add multiple metrics in one alert and add expression."
}
