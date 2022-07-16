variable "notification" {
  default = {
    "comparison_operator"        = "GREATER_THAN"
    "threshold"                  = "200"
    "threshold_type"             = "PERCENTAGE"
    "notification_type"          = "ACTUAL"
  }
}

variable "metric_alarm_billing" {
  default = {
    "alarm_name"          = "Billing-alarm"
    "comparison_operator-billing" = "GreaterThanOrEqualToThreshold"
    "evaluation_periods"  = "1"
    "metric_name"         = "EstimatedCharges"
    "namespace"           = "Billing"
    "period"              = "28800"
    "statistic"           = "Maximum"
    "threshold"           = "200"
  }
}

variable "delivery_policy" {
  type        = string
  default     = <<EOF
  { "http": { "defaultHealthyRetryPolicy": { "minDelayTarget": 20, "maxDelayTarget": 20, "numRetries": 3, "numMaxDelayRetries": 0, "numNoDelayRetries": 0, "numMinDelayRetries": 0,"backoffFunction": "linear"},"disableSubscriptionOverrides": false, "defaultThrottlePolicy": { "maxReceivesPerSecond": 1 } }}
  EOF
  description = "The access logs format to sync into cloudwatch log group"
}

variable "budget_settings" {
  default = {
    "name"         = "Account-Monthly-Budget"
    "budget_type"  = "COST"
    "limit_amount" = "200"
    "limit_unit"   = "USD"
    "time_unit"    = "MONTHLY"
    "time_period_end"   = "2087-06-15_00:00"
    "time_period_start" = "2022-01-01_00:00"
  }
}

variable "sns_subscription" {
  default = {
    "sns_subscription_email_address_list" = []
    "sns_subscription_phone_number_list" = []
    "sms_message_body" = "sms_message_body"
    "slack_webhook_url" = ""
    "slack_channel" = ""
    "slack_username" = ""
    "cloudwatch_log_group_retention_in_days" = 0
    "opsgenie_endpoint" = ["https://api.opsgenie.com/v1/json/amazonsns?apiKey=5736f9c8-409d-4b67-b922-45926096bf54"]
  }
}
