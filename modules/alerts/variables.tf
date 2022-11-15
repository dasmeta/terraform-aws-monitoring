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
    statistic          = string
    equation           = string
    threshold          = number
    period             = number
    treat_missing_data = string
    log_based_metric   = bool
    anomaly_detection  = bool
    account_id         = optional(string, null)
  }))

  description = "Allows to create standard and log based metric alarms"
  default     = []
}

# IMPORTANT: only us-east-1 (Virginia) region aws provider works with health_checks, so pleas have provider and create SNS topic in this region
variable "health_checks" {
  type = list(any)
  ## example list to pass
  # [
  #   {
  #     host = "example.com"
  #   },
  #   {
  #     host = "example.com"
  #     path = "/12345"
  #   },
  #   {
  #     host = "example.com"
  #     port = 80
  #   }
  # ]
  description = "Allows to create route53 health checks and alarms on them"
  default     = []
}

# @todo refactor to get topic from ouside but also have default value
# variable "sns_topic_name" {
#   type        = string
#   description = "Specifies the name of the Amazon SNS topic defined for notification of log file delivery"
#   default     = null
# }
