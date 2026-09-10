terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    # test = {
    #   source = "terraform.io/builtin/test"
    # }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "alerts" {
  name = "example-synthetics-alerts-basic"
}

resource "aws_secretsmanager_secret" "example" {
  name = "example/cloudwatch-synthetics/basic"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    REST_API_KEY                 = "example-key"
    REST_API_SECRET              = "example-secret"
    MONITORING_CARD_NUMBER       = "0000000000000000000"
    MONITORING_MERCHANT_ID       = "example-merchant"
    MONITORING_VERIFICATION_CODE = ""
  })
}
