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
  mock_resource "aws_iam_policy" {
    defaults = { arn = "arn:aws:iam::111122223333:policy/test" }
  }
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::111122223333:role/test" }
  }
}

override_module {
  target = module.topic
  outputs = {
    name = "security-alerts"
    arn  = "arn:aws:sns:eu-central-1:111122223333:security-alerts"
  }
}

override_module {
  target = module.fallback-topic
  outputs = {
    name = "fallback-security-alerts"
  }
}

override_module {
  target = module.dead_letter_queue
  outputs = {
    queue_name = "security-alerts-dead-letter"
    queue_arn  = "arn:aws:sqs:eu-central-1:111122223333:security-alerts-dead-letter"
  }
}

run "parallel_slack_subscriptions_build_distinct_packages" {
  command = apply

  variables {
    topic_name = "security-alerts"
    slack_webhooks = [
      { instance_key = "primary", channel = "security", username = "security-bot", hook_url = "https://example.invalid/primary" },
      { instance_key = "delivery", channel = "security", username = "security-bot", hook_url = "https://example.invalid/delivery" },
    ]
  }

  assert {
    condition     = length(module.notify_slack) == 2
    error_message = "Both Slack subscriptions must be created from the shared source."
  }
}
