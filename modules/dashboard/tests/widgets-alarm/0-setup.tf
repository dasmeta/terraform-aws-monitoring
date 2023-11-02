terraform {
  required_version = ">= 1.3"

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

resource "aws_cloudwatch_log_group" "log_group_test_c" {
  name = "test-logs-insights/dashboard-widget/c"
}

# create test alerts on top of test log groups to use them on dashboard
module "alerts" {
  source = "../../../alerts"

  alerts = [
    {
      name   = "test alert a"
      source = aws_cloudwatch_log_group.log_group_test_a.name

      filters            = {}
      statistic          = "sum"
      equation           = "gte"
      threshold          = 1
      period             = 300
      anomaly_detection  = false
      log_based_metric   = true
      treat_missing_data = null
    },
    {
      name               = "test alert b"
      source             = aws_cloudwatch_log_group.log_group_test_b.name
      filters            = {}
      statistic          = "sum"
      equation           = "gte"
      threshold          = 1
      period             = 300
      anomaly_detection  = false
      log_based_metric   = true
      treat_missing_data = null
    },
    {
      name               = "test alert c"
      source             = aws_cloudwatch_log_group.log_group_test_c.name
      filters            = {}
      statistic          = "sum"
      equation           = "gte"
      threshold          = 1
      period             = 300
      anomaly_detection  = false
      log_based_metric   = true
      treat_missing_data = "missing"
    },
  ]
}

locals {
  alert_arns = values(module.alerts.alert_data.log-based-metric-alarm).*.cloudwatch_metric_alarm_arn
}
