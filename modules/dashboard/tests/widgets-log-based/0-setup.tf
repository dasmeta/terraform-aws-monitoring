terraform {
  required_version = ">= 1.0"

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

# prepare filter on test group
module "cloudwatch_metric_filter_test" {
  source = "git::ssh://git@git.proalpha.com/cce_mod/monitoring.git//modules/metrics-filter-multiple?ref=v0.6.6"

  log_groups = {
    "test-log-based-dashboard" = aws_cloudwatch_log_group.log_group_test.name
  }

  patterns = [
    {
      name       = "error1"
      source     = "test-log-based-dashboard"
      pattern    = "ERROR"
      dimensions = {}
    },
    {
      name    = "error2"
      source  = "test-log-based-dashboard"
      pattern = "{ $.ClusterName = \"*provider-test-new3*\" }"
      dimensions = {
        "ClusterName" = "$.ClusterName"
      }
    },
    {
      name       = "error3"
      source     = "test-log-based-dashboard"
      pattern    = "ERROR"
      dimensions = {}
    }
  ]
}
