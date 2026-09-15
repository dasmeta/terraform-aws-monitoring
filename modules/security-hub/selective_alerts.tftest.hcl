mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}
mock_provider "archive" {}

variables {
  name                = "test-security-hub"
  enable_security_hub = false
  enabled_standards   = []
  config = {
    enabled = false
  }
  inspector = {
    enabled = false
  }
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_cloudwatch_event_rule.automated_alerts.state == "ENABLED"
    error_message = "The existing Security Hub route must remain enabled by default."
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.service_alerts) == 0
    error_message = "Direct service routes must be opt-in."
  }
}

run "guardduty_only" {
  command = plan

  variables {
    automated_alerts = {
      security_hub = false
      guardduty    = true
      inspector    = false
      macie        = false
    }
  }

  assert {
    condition     = aws_cloudwatch_event_rule.automated_alerts.state == "DISABLED"
    error_message = "The broad Security Hub imported-finding rule must be disabled."
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.service_alerts) == 1
    error_message = "Exactly one direct service rule must be created."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.service_alerts["guardduty"].event_pattern).source == ["aws.guardduty"]
    error_message = "The selected rule must listen directly to GuardDuty findings."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.service_alerts["guardduty"].event_pattern).detail.severity == [{ numeric = [">=", 4] }]
    error_message = "GuardDuty alerts must begin at medium severity (4)."
  }
}

run "inspector_and_macie" {
  command = plan

  variables {
    automated_alerts = {
      security_hub = false
      guardduty    = false
      inspector    = true
      macie        = true
    }
  }

  assert {
    condition     = length(aws_cloudwatch_event_rule.service_alerts) == 2
    error_message = "Inspector and Macie must each create a direct finding route."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.service_alerts["inspector"].event_pattern).detail.status == ["ACTIVE"]
    error_message = "Inspector must route only active findings."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.service_alerts["macie"].event_pattern).detail.archived == [false]
    error_message = "Macie must route only unarchived findings."
  }
}

run "guardduty_sns_delivery" {
  command = plan

  variables {
    automated_alerts = {
      security_hub = false
      guardduty    = true
    }
    alarm_actions = {
      enabled = true
    }
  }

  override_module {
    target          = module.alarm_actions[0]
    override_during = plan
    outputs = {
      topic_arn = "arn:aws:sns:eu-central-1:123456789012:test-alerts"
    }
  }

  override_resource {
    target          = aws_cloudwatch_event_rule.service_alerts["guardduty"]
    override_during = plan
    values = {
      arn = "arn:aws:events:eu-central-1:123456789012:rule/test-security-hub-guardduty-automated-trigger"
    }
  }

  assert {
    condition     = aws_cloudwatch_event_target.service_alerts_sns["guardduty"].arn == "arn:aws:sns:eu-central-1:123456789012:test-alerts"
    error_message = "The direct GuardDuty route must target the configured alert SNS topic."
  }

  assert {
    condition     = contains(one(one(data.aws_iam_policy_document.eventbridge_publish_policy[0].statement).condition).values, "arn:aws:events:eu-central-1:123456789012:rule/test-security-hub-guardduty-automated-trigger")
    error_message = "The SNS publish policy must authorize the selected GuardDuty rule."
  }
}
