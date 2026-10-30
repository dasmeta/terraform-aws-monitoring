mock_provider "aws" {
  mock_resource "aws_cloudwatch_event_rule" {
    defaults = {
      arn = "arn:aws:events:eu-central-1:111122223333:rule/example-security-hub"
    }
  }

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
    topic_arn          = "arn:aws:sns:eu-central-1:111122223333:example-security-alerts"
    slack_lambda_names = { security = "example-security-slack" }
  }
}

override_module {
  target = module.high_severity_actions
  outputs = {
    topic_arn              = "arn:aws:sns:eu-central-1:111122223333:high-security-findings"
    dead_letter_queue_name = "high-security-findings-dead-letter"
  }
}

override_module {
  target = module.security_failure_actions
  outputs = {
    topic_arn              = "arn:aws:sns:eu-central-1:111122223333:security-failure-alerts"
    dead_letter_queue_name = "security-failure-alerts-dead-letter"
  }
}

override_module {
  target = module.finding_router
  outputs = {
    lambda_function_arn  = "arn:aws:lambda:eu-central-1:111122223333:function:example-finding-router"
    lambda_function_name = "example-finding-router"
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

run "first_delivery_routes_all_severities_without_general_monitoring" {
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
      slack_webhooks = [{
        hook_url = sensitive("https://hooks.slack.com/services/example")
        channel  = "project-spm-security-alerts"
        username = "security-hub"
      }]
    }
    finding_delivery = {
      enabled           = true
      opsgenie_endpoint = sensitive("https://api.opsgenie.com/v1/json/integrations/webhooks/amazonsecurityhub?apiKey=example")
    }
    delivery_failure = {
      owner       = "security-operations"
      runbook_url = "https://example.com/runbooks/security-hub-delivery"
    }
  }

  assert {
    condition = (
      length(aws_dynamodb_table.finding_delivery) == 1 &&
      length(aws_ssm_parameter.finding_cutover) == 1 &&
      length(aws_cloudwatch_event_target.automated_alerts_sns) == 0 &&
      length(aws_cloudwatch_event_target.automated_alerts_router) == 1 &&
      !contains(keys(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings), "Severity") &&
      contains(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].alarm_actions, module.security_failure_actions[0].topic_arn) &&
      alltrue([for alarm in aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric : contains(alarm.alarm_actions, module.security_failure_actions[0].topic_arn)]) &&
      length(aws_cloudwatch_metric_alarm.finding_destination_queue_nonempty) == 2 &&
      length(aws_cloudwatch_metric_alarm.finding_destination_new_failure) == 4 &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["slack-lambda-security"].metric_name == "Errors" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["slack-lambda-security"].dimensions.FunctionName == "example-security-slack" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["router-lambda"].dimensions.FunctionName == "example-finding-router" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["slack-sns"].metric_name == "NumberOfNotificationsFailed" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["opsgenie-sns"].metric_name == "NumberOfNotificationsFailed" &&
      alltrue([for alarm in aws_cloudwatch_metric_alarm.finding_destination_new_failure : contains(alarm.alarm_actions, module.security_failure_actions[0].topic_arn)])
    )
    error_message = "First-delivery mode must route all active severities through the router and use a separate security failure topic."
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
