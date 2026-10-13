mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { id = "aws", partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-2" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-2:123456789012:account-alarms-handling" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/example-reporter" }
  }
  mock_resource "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:us-east-2:123456789012:function:example-monitoring-reporter-slack" }
  }
}

mock_provider "aws" {
  alias = "secondary"
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { id = "aws", partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_data "aws_region" {
    defaults = { name = "us-east-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:us-east-1:123456789012:account-alarms-handling-virginia" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/example-reporter-secondary" }
  }
  mock_resource "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:us-east-1:123456789012:function:example-monitoring-reporter-virginia-slack" }
  }
}

variables {
  enable_dead_letter_queue = false
  web_endpoints            = ["https://alerts.example.com/webhook"]
}

run "primary_reporter" {
  command = plan
  variables {
    topic_name = "account-alarms-handling"
    slack_webhooks = [{
      hook_url = "https://hooks.example.com/services/test"
      channel  = "example-monitoring"
      username = "reporter"
    }]
  }
  assert {
    condition     = module.notify_slack["example-monitoring-reporter"].notify_slack_lambda_function_name == "example-monitoring-reporter-slack"
    error_message = "Primary reporter identity must remain stable."
  }
}

run "secondary_reporter" {
  command   = plan
  providers = { aws = aws.secondary }
  variables {
    topic_name = "account-alarms-handling-virginia"
    slack_webhooks = [{
      hook_url = "https://hooks.example.com/services/test"
      channel  = "example-monitoring"
      username = "reporter-virginia"
    }]
  }
  assert {
    condition     = module.notify_slack["example-monitoring-reporter-virginia"].notify_slack_lambda_function_name == "example-monitoring-reporter-virginia-slack"
    error_message = "Secondary reporter identity must remain stable."
  }
}
