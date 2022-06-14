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
