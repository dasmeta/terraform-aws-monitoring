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
  name = "example-synthetics-alerts-failure"
}

resource "aws_secretsmanager_secret" "example" {
  name = "example/cloudwatch-synthetics/alarm-failure"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id = aws_secretsmanager_secret.example.id
  secret_string = jsonencode({
    username = "example-user"
    password = "example-pass"
  })
}
