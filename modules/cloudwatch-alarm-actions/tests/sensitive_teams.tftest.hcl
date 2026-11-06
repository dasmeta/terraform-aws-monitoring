mock_provider "aws" {}

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

override_module {
  target  = module.notify_teams
  outputs = {}
}

run "empty_teams_webhooks_create_no_subscription" {
  command = plan

  assert {
    condition     = length(module.notify_teams) == 0
    error_message = "An empty Teams webhook list must not create a subscription."
  }
}

run "sensitive_teams_webhook_uses_public_index" {
  command = plan

  variables {
    teams_webhooks = sensitive(["https://example.com/teams"])
  }

  assert {
    condition     = length(module.notify_teams) == 1 && contains(keys(module.notify_teams), "0")
    error_message = "A sensitive Teams webhook must use a public stable index for its subscription."
  }
}
