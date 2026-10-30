mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { name = "eu-central-1" }
  }
}

mock_provider "archive" {}
mock_provider "external" {}
mock_provider "local" {}

override_module {
  target = module.notify_slack
}

run "sensitive_slack_url_keeps_public_instance_key" {
  command = plan

  variables {
    topic_name               = "security-hub-findings"
    enable_dead_letter_queue = false
    slack_webhooks = [{
      hook_url = sensitive("https://hooks.slack.com/services/example")
      channel  = "security-alerts"
      username = "security-hub"
    }]
  }

  assert {
    condition     = contains(keys(module.notify_slack), "security-alerts-security-hub")
    error_message = "Slack instance keys must use the public channel and username even when the webhook URL is sensitive."
  }
}

run "explicit_instance_key_survives_channel_change" {
  command = plan

  variables {
    topic_name               = "security-hub-findings"
    enable_dead_letter_queue = false
    slack_webhooks = [{
      hook_url     = sensitive("https://hooks.slack.com/services/example-security")
      channel      = "project-spm-security-alerts"
      username     = "security-hub"
      instance_key = "proejct-spm-monitoring-security-hub"
    }]
  }

  assert {
    condition     = contains(keys(module.notify_slack), "proejct-spm-monitoring-security-hub") && !contains(keys(module.notify_slack), "project-spm-security-alerts-security-hub")
    error_message = "Changing the channel must preserve the explicit Terraform instance key."
  }
}
