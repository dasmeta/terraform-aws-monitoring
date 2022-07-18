variable "comparison_operator" {
  type    = string
  default = "GREATER_THAN"
}

variable "threshold" {
  type    = string
  default = "200"
}

variable "threshold_type" {
  type    = string
  default = "PERCENTAGE"
}

variable "notification_type" {
  type    = string
  default = "ACTUAL"
}

variable "statistic" {
  type    = string
  default = "Maximum"
}

variable "period" {
  type    = string
  default = "28800"
}

variable "namespace" {
  type    = string
  default = "Billing"
}

variable "alarm_name" {
  type    = string
  default = "Billing-alarm"
}

variable "comparison_operator_billing" {
  type    = string
  default = "GreaterThanOrEqualToThreshold"
}

variable "evaluation_periods" {
  type    = string
  default = "1"
}

variable "metric_name" {
  type    = string
  default = "EstimatedCharges"
}

variable "delivery_policy" {
  type        = string
  default     = <<EOF
  { "http": { "defaultHealthyRetryPolicy": { "minDelayTarget": 20, "maxDelayTarget": 20, "numRetries": 3, "numMaxDelayRetries": 0, "numNoDelayRetries": 0, "numMinDelayRetries": 0,"backoffFunction": "linear"},"disableSubscriptionOverrides": false, "defaultThrottlePolicy": { "maxReceivesPerSecond": 1 } }}
  EOF
  description = "The access logs format to sync into cloudwatch log group"
}

variable "name" {
  type    = string
  default = "Account-Monthly-Budget"
}

variable "budget_type" {
  type    = string
  default = "COST"
}

variable "limit_amount" {
  type    = string
  default = "200"
}

variable "limit_unit" {
  type    = string
  default = "USD"
}

variable "time_unit" {
  type    = string
  default = "MONTHLY"
}

variable "time_period_end" {
  type    = string
  default = "2087-06-15_00:00"
}

variable "time_period_start" {
  type    = string
  default = "2022-01-01_00:00"
}

variable "sns_subscription" {
  default = {
    "sns_subscription_email_address_list"    = []
    "sns_subscription_phone_number_list"     = []
    "sms_message_body"                       = "sms_message_body"
    "slack_webhook_url"                      = ""
    "slack_channel"                          = ""
    "slack_username"                         = ""
    "cloudwatch_log_group_retention_in_days" = 0
    "opsgenie_endpoint"                      = ["https://api.opsgenie.com/v1/json/amazonsns?apiKey=5736f9c8-409d-4b67-b922-45926096bf54"]
  }
}
