terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type        = string
  description = "AWS Region for this Security Hub route."
}

variable "security_slack_webhook_url" {
  type        = string
  sensitive   = true
  description = "Webhook for the dedicated security Slack channel."
}

variable "security_opsgenie_api_key" {
  type        = string
  sensitive   = true
  description = "Opsgenie Alert API integration key with create, update, read, and close permissions."
}

variable "security_runbook_url" {
  type        = string
  description = "HTTPS runbook for security delivery failure investigation and replay."
}
