terraform {
  required_providers {
    test = {
      source = "terraform.io/builtin/test"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.33"
    }
  }
}

provider "aws" {}

# prepare test log groups
resource "aws_cloudwatch_log_group" "log_group_test_a" {
  name = "test-logs-insights/dashboard-widget/a"
}

resource "aws_cloudwatch_log_group" "log_group_test_b" {
  name = "test-logs-insights/dashboard-widget/b"
}
