mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:eu-central-1:111122223333:example-security-hub-eventbridge-failures"
      id  = "https://sqs.eu-central-1.amazonaws.com/111122223333/example-security-hub-eventbridge-failures"
      url = "https://sqs.eu-central-1.amazonaws.com/111122223333/example-security-hub-eventbridge-failures"
    }
  }

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
    condition     = length(aws_cloudwatch_event_target.automated_alerts_sns) == 0 && length(aws_sqs_queue.eventbridge_failed_delivery) == 0 && length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty) == 0 && length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric) == 0
    error_message = "Disabled alerting must create neither an SNS target nor a delivery failure queue."
  }
}

run "enabled_has_current_finding_filter_and_failure_capture" {
  command = apply

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
    delivery_failure = {
      owner                = "security-operations"
      escalation_topic_arn = "arn:aws:sns:eu-central-1:111122223333:security-escalation"
      runbook_url          = "https://example.com/runbooks/security-hub-delivery"
    }
  }

  assert {
    condition = (
      jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings.Workflow.Status == ["NEW", "NOTIFIED"] &&
      jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings.RecordState == ["ACTIVE"] &&
      jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings.Severity.Label == ["CRITICAL", "HIGH"] &&
      length(aws_sqs_queue.eventbridge_failed_delivery) == 1 &&
      aws_sqs_queue.eventbridge_failed_delivery[0].message_retention_seconds == 1209600 &&
      aws_sqs_queue.eventbridge_failed_delivery[0].sqs_managed_sse_enabled &&
      length(aws_cloudwatch_event_target.automated_alerts_sns[0].dead_letter_config) == 1 &&
      length(aws_cloudwatch_event_target.manual_alerts_sns[0].dead_letter_config) == 1 &&
      aws_cloudwatch_event_target.automated_alerts_sns[0].retry_policy[0].maximum_event_age_in_seconds == 86400 &&
      aws_cloudwatch_event_target.manual_alerts_sns[0].retry_policy[0].maximum_retry_attempts == 185 &&
      length(jsondecode(aws_sqs_queue_policy.eventbridge_failed_delivery[0].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"]) == 2 &&
      contains(jsondecode(aws_sqs_queue_policy.eventbridge_failed_delivery[0].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"], aws_cloudwatch_event_rule.automated_alerts.arn) &&
      contains(jsondecode(aws_sqs_queue_policy.eventbridge_failed_delivery[0].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"], aws_cloudwatch_event_rule.manual_alerts[0].arn) &&
      length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric) == 4 &&
      aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric["automatic-InvocationsFailedToBeSentToDlq"].metric_name == "InvocationsFailedToBeSentToDlq" &&
      aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric["manual-InvocationsSentToDlq"].dimensions.RuleName == aws_cloudwatch_event_rule.manual_alerts[0].name &&
      aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].metric_name == "ApproximateNumberOfMessagesVisible" &&
      length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].alarm_actions) == 1 &&
      contains(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].alarm_actions, var.delivery_failure.escalation_topic_arn) &&
      length(output.eventbridge_failed_delivery_alarm_arns) == 5 &&
      output.eventbridge_failed_delivery_queue_arn == aws_sqs_queue.eventbridge_failed_delivery[0].arn &&
      output.eventbridge_failed_delivery_queue_url == aws_sqs_queue.eventbridge_failed_delivery[0].url &&
      output.manual_eventbridge_rule_arn == aws_cloudwatch_event_rule.manual_alerts[0].arn &&
      output.delivery_failure_response.owner == "security-operations"
    )
    error_message = "Enabled critical/high alerting must filter unresolved findings and retain failed deliveries for both targets."
  }
}

run "reject_enabled_alerting_without_failure_owner" {
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

  expect_failures = [aws_sqs_queue.eventbridge_failed_delivery]
}

run "reject_shared_failure_escalation_topic" {
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
    delivery_failure = {
      owner                = "security-operations"
      escalation_topic_arn = "arn:aws:sns:eu-central-1:111122223333:example-security-alerts"
      runbook_url          = "https://example.com/runbooks/security-hub-delivery"
    }
  }

  expect_failures = [aws_sqs_queue.eventbridge_failed_delivery]
}
