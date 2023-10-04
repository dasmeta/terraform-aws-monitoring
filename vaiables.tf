variable "region" {
  description = "The region where resources should be managed. In this repository it's secondary because IAM is always global."
  type        = string
  default     = "eu-central-1"
}

variable "name" {
  type        = string
  description = "Dashboard name"
}

variable "health_checks" {
  type        = any
  default     = []
  description = "Health_checks endpoints and paths"
}

variable "create_alerts" {
  type        = bool
  default     = true
  description = "Create Alert"
}

variable "sns_topic_name" {
  type        = string
  default     = "cloudwatch-alarm"
  description = "SNS topic name"
}

variable "enable_log_base_metrics" {
  type    = bool
  default = true
}

variable "log_base_metrics" {
  type        = any
  default     = []
  description = "Log Base Metrics"
}

variable "alerts" {
  type        = any
  default     = []
  description = "Alerts"
}

variable "expression_alert" {
  type        = any
  default     = {}
  description = "Add multiple metrics in one alert and add expression."
}

variable "application_channel_alerts" {
  type        = any
  default     = []
  description = "Application channel alerts"
}

variable "eks_monitroing_dashboard" {
  type        = any
  default     = []
  description = "Dashboard for monitoring EKS cluster"
}

variable "application_monitroing_dashboard" {
  type        = any
  default     = []
  description = "Application for monitoring EKS cluster"
}
