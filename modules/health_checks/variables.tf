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

variable "sns_topic" {
  type        = string
  default     = "cloudwatch-alerts"
  description = "The name of aws sns topic use as target for alarm actions"
}
