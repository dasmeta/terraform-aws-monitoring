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

variable "create_application_channel" {
  type        = bool
  default     = true
  description = "Create application alert"
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

variable "webhook_url" {
  type        = string
  description = "Teams Webhook URL"
}

variable "application_channel_webhook_url" {
  type        = string
  description = "Application Teams Channel Webhook URL"
}

variable "alerts" {
  type        = any
  default     = []
  description = "Alerts"
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

variable "fallback_email_addresses" {
  type        = list(string)
  default     = []
  description = "List of fallback email addresses to send notification when lambda failed"
}

variable "fallback_phone_numbers" {
  type        = list(string)
  default     = []
  description = "List of international formatted phone number to send notification when lambda failed"
}

variable "enable_teams_notifications" {
  type        = bool
  default     = false
  description = "Enable Teams notifications"
}
