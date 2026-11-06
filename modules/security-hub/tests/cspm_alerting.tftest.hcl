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
    dead_letter_queue_arn  = "arn:aws:sqs:eu-central-1:111122223333:high-security-findings-dead-letter"
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

override_module {
  target = module.opsgenie_api_notifier
  outputs = {
    lambda_function_arn  = "arn:aws:lambda:eu-central-1:111122223333:function:example-opsgenie-api"
    lambda_function_name = "example-opsgenie-api"
  }
}

override_module {
  target = module.finding_group_digest
  outputs = {
    lambda_function_arn  = "arn:aws:lambda:eu-central-1:111122223333:function:example-finding-group-digest"
    lambda_function_name = "example-finding-group-digest"
  }
}

run "grouped_mode_reconciles_all_findings_and_monitors_digest_failures" {
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
      slack_webhooks = [{
        hook_url = sensitive("https://hooks.slack.com/services/example")
        channel  = "security-alerts"
        username = "security-hub"
      }]
    }
    finding_delivery = {
      enabled               = true
      notification_mode     = "grouped"
      opsgenie_api_key      = sensitive("example-api-key")
      opsgenie_alert_prefix = "Example"
    }
  }

  assert {
    condition = (
      length(module.finding_group_digest) == 1 &&
      module.finding_router[0].lambda_function_name != module.finding_group_digest[0].lambda_function_name &&
      aws_cloudwatch_event_rule.finding_group_digest[0].schedule_expression == "rate(15 minutes)" &&
      length(aws_cloudwatch_event_target.finding_group_digest) == 1 &&
      length([for index in aws_dynamodb_table.finding_delivery[0].global_secondary_index : index
      if index.name == "notification-state" && index.hash_key == "notification_state"]) == 1 &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["group-digest-lambda"].metric_name == "Errors" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["group-digest-lambda"].treat_missing_data == "ignore" &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["group-digest-lambda"].evaluation_periods == 3 &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["group-digest-lambda"].datapoints_to_alarm == 1 &&
      length(aws_cloudwatch_metric_alarm.finding_group_digest_duration) == 1 &&
      aws_cloudwatch_metric_alarm.finding_group_digest_duration[0].threshold == 720000 &&
      contains(jsondecode(aws_sqs_queue_policy.eventbridge_failed_delivery[0].policy).Statement[0].Condition.ArnEquals["aws:SourceArn"], aws_cloudwatch_event_rule.finding_group_digest[0].arn) &&
      !contains(keys(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings), "RecordState") &&
      !contains(keys(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings), "Workflow") &&
      contains(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings["$or"][0].Severity.Label, "HIGH") &&
      contains(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings["$or"][0].Severity.Label, "CRITICAL") &&
      contains(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern).detail.findings["$or"][1].ProductName, "GuardDuty")
    )
    error_message = "Grouped mode must route urgent findings immediately, reconcile routine findings on schedule, and monitor digest delivery."
  }
}

run "api_mode_tracks_resolution_and_uses_lambda_subscription" {
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
        channel  = "example-security-alerts"
        username = "security-hub"
      }]
    }
    finding_delivery = {
      enabled               = true
      opsgenie_api_key      = sensitive("example-api-key")
      opsgenie_alert_prefix = "Example"
    }
  }

  assert {
    condition = (
      length(module.opsgenie_api_notifier) == 1 &&
      length(aws_sns_topic_subscription.opsgenie_api) == 1 &&
      length(aws_cloudwatch_event_target.automated_alerts_router) == 1 &&
      length(aws_cloudwatch_metric_alarm.finding_group_digest_duration) == 0 &&
      !contains(keys(jsondecode(aws_cloudwatch_event_rule.automated_alerts.event_pattern)), "detail") &&
      aws_cloudwatch_metric_alarm.finding_destination_new_failure["opsgenie-api-lambda"].metric_name == "Errors"
    )
    error_message = "API mode must receive resolution events, subscribe the Opsgenie Lambda, and monitor Lambda errors."
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
    condition     = length(aws_cloudwatch_event_target.automated_alerts_sns) == 0 && length(aws_sqs_queue.eventbridge_failed_delivery) == 0 && length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty) == 0 && length(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_metric) == 0 && length(aws_cloudwatch_metric_alarm.finding_group_digest_duration) == 0
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
      enabled         = true
      create_topic    = false
      topic_name      = "example-security-alerts"
      email_addresses = ["security@example.com"]
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
      contains(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].alarm_actions, module.security_failure_actions[0].topic_arn) &&
      length(output.eventbridge_failed_delivery_alarm_arns) == 5 &&
      output.eventbridge_failed_delivery_queue_arn == aws_sqs_queue.eventbridge_failed_delivery[0].arn &&
      output.eventbridge_failed_delivery_queue_url == aws_sqs_queue.eventbridge_failed_delivery[0].url &&
      output.manual_eventbridge_rule_arn == aws_cloudwatch_event_rule.manual_alerts[0].arn &&
      output.delivery_failure_topic_arn == module.security_failure_actions[0].topic_arn
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
        channel  = "example-security-alerts"
        username = "security-hub"
      }]
    }
    finding_delivery = {
      enabled           = true
      opsgenie_endpoint = sensitive("https://api.opsgenie.com/v1/json/integrations/webhooks/amazonsecurityhub?apiKey=example")
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

run "create_separate_failure_topic_without_owner_metadata" {
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
      enabled         = true
      create_topic    = false
      topic_name      = "example-security-alerts"
      email_addresses = ["security@example.com"]
    }
  }

  assert {
    condition = (
      length(module.security_failure_actions) == 1 &&
      module.security_failure_actions[0].topic_arn != module.alarm_actions[0].topic_arn &&
      contains(aws_cloudwatch_metric_alarm.eventbridge_failed_delivery_queue_nonempty[0].alarm_actions, module.security_failure_actions[0].topic_arn) &&
      output.delivery_failure_topic_arn == module.security_failure_actions[0].topic_arn
    )
    error_message = "Alert delivery failures must use a separate module-owned SNS topic without client owner metadata."
  }
}

run "reject_delivery_failure_topic_without_recipients" {
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

run "teams_follow_normal_slack_stream" {
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
    alarm_actions                          = { enabled = true, create_topic = false, topic_name = "example-security-alerts" }
    finding_delivery = {
      enabled           = true
      notification_mode = "grouped"
      opsgenie_api_key  = sensitive("example-api-key")
      teams_delivery    = "slack"
      teams_webhooks    = [sensitive("https://example.com/teams")]
    }
  }

  assert {
    condition     = length(try(nonsensitive(local.finding_teams_to_slack), local.finding_teams_to_slack)) == 1 && length(try(nonsensitive(local.finding_teams_to_opsgenie), local.finding_teams_to_opsgenie)) == 0
    error_message = "Slack Teams mode must subscribe only to the normal topic."
  }
}

run "teams_follow_urgent_opsgenie_stream" {
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
    alarm_actions                          = { enabled = true, create_topic = false, topic_name = "example-security-alerts" }
    finding_delivery = {
      enabled           = true
      notification_mode = "grouped"
      opsgenie_api_key  = sensitive("example-api-key")
      teams_delivery    = "opsgenie"
      teams_webhooks    = [sensitive("https://example.com/teams")]
    }
  }

  assert {
    condition     = length(try(nonsensitive(local.finding_teams_to_slack), local.finding_teams_to_slack)) == 0 && length(try(nonsensitive(local.finding_teams_to_opsgenie), local.finding_teams_to_opsgenie)) == 1
    error_message = "Opsgenie Teams mode must subscribe only to the urgent topic."
  }
}

run "teams_follow_both_streams" {
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
    alarm_actions                          = { enabled = true, create_topic = false, topic_name = "example-security-alerts" }
    finding_delivery = {
      enabled           = true
      notification_mode = "grouped"
      opsgenie_api_key  = sensitive("example-api-key")
      teams_delivery    = "both"
      teams_webhooks    = [sensitive("https://example.com/teams")]
    }
  }

  assert {
    condition     = length(try(nonsensitive(local.finding_teams_to_slack), local.finding_teams_to_slack)) == 1 && length(try(nonsensitive(local.finding_teams_to_opsgenie), local.finding_teams_to_opsgenie)) == 1
    error_message = "Both Teams mode must subscribe to both topics."
  }
}
