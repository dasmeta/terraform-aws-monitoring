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

// TODO: seems the aws_budgets_budget is able to notify about billing, do we really need the following manual alert?
# variable "statistic" {
#   type    = string
#   default = "Maximum"
# }

# variable "period" {
#   type    = string
#   default = "28800"
# }

# variable "namespace" {
#   type    = string
#   default = "Billing"
# }

# variable "alarm_name" {
#   type    = string
#   default = "Billing-alarm"
# }

# variable "comparison_operator_billing" {
#   type    = string
#   default = "GreaterThanOrEqualToThreshold"
# }

# variable "evaluation_periods" {
#   type    = string
#   default = "1"
# }

# variable "metric_name" {
#   type    = string
#   default = "EstimatedCharges"
# }

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

variable "sns_topic_arns" {
  type        = list(string)
  default     = []
  description = "The arns of aws sns topic use as target for notifying about cost increase, either this or notify_email_addresses should be set"
}

variable "notify_email_addresses" {
  type        = list(string)
  default     = []
  description = "The email addresses to notify about about cost increase, either this or sns_topic_arns should be set"
}
