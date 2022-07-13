variable "account_name" {
  type    = string
  default = "Das Meta"
}

variable "name" {
  type    = string
  default = "account-billing-alarm-topic"
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

variable "threshold_type" {
  type    = string
  default = "PERCENTAGE"
}

variable "notification_type" {
  type    = string
  default = "FORECASTED"
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
  default = "AWS/Billing"
}

variable "period" {
  type    = string
  default = "28800"
}

variable "statistic" {
  type    = string
  default = "Maximum"
}

variable "protocol" {
  type    = string
  default = "https"
}


variable "opsgenie-webhook" {
  type        = string
  description = "Webhook for sending notification to opsgenie"
  default     = ""
}