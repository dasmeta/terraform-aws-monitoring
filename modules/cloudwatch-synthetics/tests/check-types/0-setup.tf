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
  name = "example-synthetics-alerts-check-types"
}

resource "aws_secretsmanager_secret" "example" {
  name = "example/cloudwatch-synthetics/check-types"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username      = "example-user"
    password      = "example-pass"
    token         = "example-token"
    api_key       = "example-api-key"
    client_id     = "example-client"
    client_secret = "example-client-secret"
    soap_action   = "http://example.com/CardInfo"
  })
}
