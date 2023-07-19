variable "name" {
  type        = string
  description = "Name"
}

variable "create_teams_target" {
  type        = bool
  default     = false
  description = "Create Target for send notification to Teams"
}

variable "create_sns_target" {
  type        = bool
  default     = false
  description = "Create Target for send notification to SNS"
}

variable "create_slack_target" {
  type        = bool
  default     = false
  description = "Create Target for send notification to Slack"
}

variable "sns_opsgenie_subscription" {
  type        = string
  default     = ""
  description = "Webhook for sending notification to opsgenie"
}

variable "sns_email_subscription" {
  type        = string
  default     = ""
  description = "Webhook for sending notification to Email"
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

variable "lambda_environment_variables" {
  description = "Environment variables to pass to Lambda function"
  type        = map(any)
  default     = {}
}

variable "securityhub_members" {
  description = "Security Hub Member Accounts (Email and Account Id)"
  type        = map(any)
  default     = {}
}
