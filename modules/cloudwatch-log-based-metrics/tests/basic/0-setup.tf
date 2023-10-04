terraform {
  required_version = "~> 1.3"

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

# prepare test log group
resource "aws_cloudwatch_log_group" "log_group_test" {
  name = "test-log-based-dashboard-logs"
}
