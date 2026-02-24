terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# set value with env variable `export TF_VAR_slack_webhook_url="https://hooks.slack.com/services/xyz/xyzop/xyzopqrst"` and `export TF_VAR_slack_channel_name="test-webhooks-channel"`
variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL"
  default     = "https://hooks.slack.com/services/xyz/xyzop/xyzopqrst"
}

variable "slack_channel_name" {
  type        = string
  description = "Slack channel name"
  default     = "test-webhooks-channel"
}
