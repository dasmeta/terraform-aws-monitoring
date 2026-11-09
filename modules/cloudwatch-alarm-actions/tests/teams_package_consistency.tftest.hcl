# Exercise real archive creation and the Lambda wrapper on a clean runner.
# Parent SNS resources defer the Teams data sources until apply.
mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { id = "aws" }
  }
  mock_data "aws_region" {
    defaults = { name = "eu-central-1", region = "eu-central-1" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111122223333" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  mock_data "aws_lambda_function" {
    defaults = { arn = "arn:aws:lambda:eu-central-1:111122223333:function:example" }
  }
  mock_data "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:eu-central-1:111122223333:example" }
  }
  mock_resource "aws_sns_topic" {
    defaults = { arn = "arn:aws:sns:eu-central-1:111122223333:example" }
  }
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::111122223333:policy/example" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/example" }
  }
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:eu-central-1:111122223333:function:example"
      qualified_arn = "arn:aws:lambda:eu-central-1:111122223333:function:example:1"
      version       = "1"
    }
  }
}

variables {
  topic_name               = "example-security-alerts"
  enable_dead_letter_queue = false
  teams_webhooks = sensitive([
    "https://example.invalid/teams-primary",
    "https://example.invalid/teams-secondary",
  ])
}

run "clean_runner_builds_both_teams_packages" {
  command = apply

  assert {
    condition     = length(module.notify_teams) == 2 && module.notify_teams["0"].name != module.notify_teams["1"].name
    error_message = "Both Teams subscriptions must deploy with distinct function identities from a clean build directory."
  }
}

run "existing_packages_remain_consistent" {
  command = apply

  assert {
    condition     = length(module.notify_teams) == 2
    error_message = "Existing Teams packages must remain usable on a repeated apply."
  }
}
