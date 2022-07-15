variable "name" {
  type    = string
  default = "Account-Monthly-Budget"
}

variable "account_budget_limit" {
  type    = string
  default = "200"
}

variable "budget_type" {
  type    = string
  default = "COST"
}

variable "limit_unit" {
  type    = string
  default = "USD"
}

variable "time_unit" {
  type    = string
  default = "MONTHLY"
}

variable "comparison_operator" {
  type    = string
  default = "GREATER_THAN"
}

variable "threshold" {
  type    = string
  default = "200"
}

variable "time_period_end"{
  type = string
  default =  "2087-06-15_00:00"
}

variable "time_period_start" {
  type = string
  default = "2022-01-01_00:00"
}

variable "threshold_type" {
  type    = string
  default = "PERCENTAGE"
}

variable "notification_type" {
  type    = string
  default = "ACTUAL"
}

variable "alarm_name" {
  type    = string
  default = "Billing-alarm"
}

variable "evaluation_periods" {
  type    = string
  default = "1"
}

variable "metric_name" {
  type    = string
  default = "EstimatedCharges"
}

variable "namespace" {
  type    = string
  default = "Billing"
}

variable "period" {
  type    = string
  default = "28800"
}

variable "statistic" {
  type    = string
  default = "Maximum"
}

variable "sns_subscription_email_address_list" {
  type        = list(string)
  default     = []
  description = "List of email addresses"
}

variable "sns_subscription_phone_number_list" {
  type        = list(string)
  default     = []
  description = "List of telephone numbers to subscribe to SNS."
}

variable "sms_message_body" {
  type    = string
  default = "sms_message_body"
}

variable "slack_hook_url" {
  type        = string
  default     = ""
  description = "This is slack webhook url path without domain"
}

variable "slack_channel" {
  type        = string
  default     = ""
  description = "Slack Channel"
}

variable "slack_username" {
  type        = string
  default     = ""
  description = "Slack User Name"
}

variable "opsgenie_endpoint" {
  type        = list(string)
  default     = []
  description = "Opsigenie platform integration url"
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in log group for Lambda."
  type        = number
  default     = 0
}
