mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      name = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

override_module {
  target = module.alarm_actions
  outputs = {
    topic_arn = "arn:aws:sns:eu-central-1:111122223333:example-security-alerts"
  }
}

run "disabled_has_no_delivery_target_or_queue" {
  command = plan

  variables {
    name                                   = "example-security-hub"
    enable_security_hub                    = false
    enable_security_hub_finding_aggregator = false
    config                                 = { enabled = false }
    inspector                              = { enabled = false }
    guardduty                              = { enabled = false }
    macie                                  = { enabled = false }
    enabled_standards                      = []
  }

  assert {
    condition     = length(aws_cloudwatch_event_target.automated_alerts_sns) == 0 && length(aws_sqs_queue.eventbridge_failed_delivery) == 0
    error_message = "Disabled alerting must create neither an SNS target nor a delivery failure queue."
  }
}

run "enabled_has_current_finding_filter_and_failure_capture" {
  command = plan

  variables {
    name                                   = "example-security-hub"
    enable_security_hub                    = false
    enable_security_hub_finding_aggregator = false
    config                                 = { enabled = false }
    inspector                              = { enabled = false }
    guardduty                              = { enabled = false }
    macie                                  = { enabled = false }
    enabled_standards                      = []
    alarm_actions = {
      enabled      = true
      create_topic = false
      topic_name   = "example-security-alerts"
    }
  }

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings.Workflow.Status == ["NEW", "NOTIFIED"] &&
      jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings.Severity.Label == ["CRITICAL", "HIGH"] &&
      length(aws_sqs_queue.eventbridge_failed_delivery) == 1 &&
      length(aws_cloudwatch_event_target.automated_alerts_sns[0].dead_letter_config) == 1 &&
      length(aws_cloudwatch_event_target.manual_alerts_sns[0].dead_letter_config) == 1
    )
    error_message = "Enabled critical/high alerting must filter unresolved findings and retain failed deliveries for both targets."
  }
}
