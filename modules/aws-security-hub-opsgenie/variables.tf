variable "securityhub-name" {
  type    = string
  default = "Send-to-SNS"
}

variable "opsgenie-webhook" {
  type        = string
  description = "Webhook for sending notification to opsgenie"
}

variable "sns-topic-name" {
  type        = string
  description = "Topic name"
  default     = "Send-to-Opsgenie"
}

variable "protocol" {
  type    = string
  default = "https"
}

variable "link-mode" {
  type    = string
  default = "ALL_REGIONS"
}



variable "name" {
  default     = "securityhub"
  description = "Moniker to apply to or prefix all resources in the module"
  type        = string
}

variable "tags" {
  default     = {}
  description = "User-Defined tags"
  type        = map(string)
}

########################################
# Notification ARNs
########################################

variable "custom_action_notification_arn" {
  default     = null
  description = "Notification ARN to send custom actions to (leave blank if not using custom actions)"
  type        = string
}

variable "imported_finding_notification_arn" {
  default     = null
  description = "Notification ARN to send imported findings to (leave blank if not using custom actions)"
  type        = string
}