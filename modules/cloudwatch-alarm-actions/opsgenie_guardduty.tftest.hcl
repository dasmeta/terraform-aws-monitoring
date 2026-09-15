mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name   = "eu-central-1"
      region = "eu-central-1"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:root"
    }
  }
  mock_data "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:eu-central-1:123456789012:test-alerts"
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
mock_provider "archive" {}
mock_provider "external" {}
mock_provider "local" {}
mock_provider "null" {}

variables {
  topic_name               = "test-alerts"
  enable_dead_letter_queue = false
}

override_module {
  target = module.topic
  outputs = {
    name = "test-alerts"
    arn  = "arn:aws:sns:eu-central-1:123456789012:test-alerts"
  }
}

run "disabled_by_default" {
  command = plan

  assert {
    condition     = output.opsgenie_guardduty_enrichment == null
    error_message = "Existing consumers must not create an Opsgenie updater by default."
  }
}

run "enabled_enrichment" {
  command = plan

  variables {
    web_endpoints = ["https://example.com/opsgenie"]
    opsgenie_guardduty_enrichment = {
      enabled = true
      api_key = "test-api-key"
    }
  }

  assert {
    condition     = length(module.notify_opsgenie_guardduty) == 1
    error_message = "Enabling enrichment must create the managed GuardDuty updater."
  }

  assert {
    condition     = length(module.fallback-topic) == 1
    error_message = "Enrichment must have a fallback topic for Lambda failure alerts."
  }

  assert {
    condition     = length(local.subscriptions) == 1 && local.subscriptions[0].protocol == "https"
    error_message = "The existing HTTPS alert-creation subscription must remain configured."
  }
}

run "enabled_requires_api_key" {
  command = plan

  variables {
    opsgenie_guardduty_enrichment = {
      enabled = true
    }
  }

  expect_failures = [var.opsgenie_guardduty_enrichment]
}
