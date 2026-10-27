terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# set value with env variable `export TF_VAR_teams_webhook_url="https://hypoportsystems.webhook.office.com/webhookb2//IncomingWebhook/..."`
variable "teams_webhook_url" {
  type        = string
  description = "Microsoft Teams webhook URL"
  default     = "https://hypoportsystems.webhook.office.com/webhookb2//IncomingWebhook/"
}

variable "delivery_failure" {
  description = "Owned escalation topic and drain/replay runbook for failed Security Hub event delivery"
  type = object({
    owner                = string
    escalation_topic_arn = string
    runbook_url          = string
  })
}
