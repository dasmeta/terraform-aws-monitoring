terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_sns_topic" "alerts" {
  name = "example-synthetics-alerts-${random_id.suffix.hex}"
}

resource "aws_secretsmanager_secret" "example" {
  name                    = "example/cloudwatch-synthetics/basic-${random_id.suffix.hex}"
  recovery_window_in_days = 0
}

resource "aws_kms_key" "customer_secret" {
  description             = "Neutral test key for CloudWatch Synthetics fixture secret."
  deletion_window_in_days = 7
}

resource "aws_secretsmanager_secret" "customer_key" {
  name                    = "example/cloudwatch-synthetics/customer-key-${random_id.suffix.hex}"
  kms_key_id              = aws_kms_key.customer_secret.arn
  recovery_window_in_days = 0
}
