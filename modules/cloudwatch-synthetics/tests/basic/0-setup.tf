terraform {
  required_version = "~> 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_sns_topic" "alerts" {
  name = "example-synthetics-alerts-basic"
}

resource "aws_secretsmanager_secret" "example" {
  name                    = "example/cloudwatch-synthetics/basic"
  recovery_window_in_days = 0
}

data "archive_file" "fixture" {
  type        = "zip"
  output_path = "${path.module}/fixture.zip"

  source {
    content  = file("${path.module}/../fixtures/python/canary.py")
    filename = "python/canary.py"
  }
}
