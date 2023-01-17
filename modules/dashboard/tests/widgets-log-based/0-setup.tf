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
  source = "../../../cloudwatch-log-based-metrics" # TODO: change to remote registry

  log_group_name = aws_cloudwatch_log_group.log_group_test.name

  metrics_patterns = [
    {
      name       = "error1"
      pattern    = "ERROR"
      dimensions = {}
    },
    {
      name    = "error2"
      pattern = "{ $.ClusterName = \"*provider-test-new3*\" }"
      dimensions = {
        "ClusterName" = "$.ClusterName"
      }
    },
    {
      name       = "error3"
      pattern    = "ERROR"
      dimensions = {}
    }
  ]
}
