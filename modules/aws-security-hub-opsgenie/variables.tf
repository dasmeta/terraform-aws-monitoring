variable "securityhub_action_target_name" {
  type    = string
  default = "Send-to-SNS"
}

variable "opsgenie_webhook" {
  type        = string
  description = "Webhook for sending notification to opsgenie"
}

variable "sns_topic_name" {
  type        = string
  description = "Topic name"
  default     = "Send-to-Opsgenie"
}

variable "protocol" {
  type    = string
  default = "https"
}

variable "link_mode" {
  type    = string
  default = "ALL_REGIONS"
}

variable "enable_security_hub" {
  type        = bool
  default     = true
  description = "Whether to enable/activate security hub and its finding aggregator for aws account, this is useful in case the security hub is already enabled (for example when we test, or account have it enable by default)"
}

variable "enable_security_hub_finding_aggregator" {
  type        = bool
  default     = true
  description = "Whether to enable/create security hub and its finding aggregator for aws account, this is useful in case there is already created security hub finding aggregator"
}
