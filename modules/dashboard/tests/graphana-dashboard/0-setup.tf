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

    grafana = {
      source  = "grafana/grafana"
      version = ">= 1.13.3"
    }
  }
}

provider "aws" {}

provider "grafana" {
  # url  = "{api-url}" ## use `export GRAFANA_URL={api-url}` bash command to set this variable value in your terminal/env
  # auth = "{api-key}" ## use `export GRAFANA_AUTH={api-key}` bash command to set this variable value in your terminal/env
}

# prepare test log groups
resource "aws_cloudwatch_log_group" "log_group_test_a" {
  name = "test-logs-insights/dashboard-widget/a"
}

resource "aws_cloudwatch_log_group" "log_group_test_b" {
  name = "test-logs-insights/dashboard-widget/b"
}

# TODO: the log groups are cluster are from ak account sandbox cluster
locals {
  rows = [
    [
      {
        type  = "logs-insight/metric",
        title = "Cluster Logs"
        sources = [
          "/aws/eks/sandbox/cluster"
        ]
        stats = [
          "count(@message)"
        ]
        query       = <<-EOT
        fields @timestamp, @message
        | sort @timestamp desc
        EOT
        time_period = "30s"
      },
      {
        type  = "logs-insight/metric",
        title = "Cluster Errors"
        sources = [
          "/aws/eks/sandbox/cluster"
        ]
        stats = [
          "count(@message)"
        ]
        query       = <<-EOT
        fields @timestamp, @message
        | filter @message like "error"
        | sort @timestamp desc
        EOT
        time_period = "30s"
      },
      {
        type  = "logs-insight/metric",
        title = "Cluster Events"
        sources = [
          "/aws/eks/sandbox/cluster"
        ]
        stats = [
          "count(@message)"
        ]
        query       = <<-EOT
        fields @timestamp, @message
        | filter @message like "event"
        | sort @timestamp desc
        EOT
        time_period = "30s"
      }
    ],

    [
      {
        type : "container/cpu",
        width : 6
      },
      {
        type : "container/memory",
        width : 6
      },
      {
        type : "container/network",
        width : 6
      },
      {
        type : "container/restarts",
        width : 6
      },
    ]
  ]
}
