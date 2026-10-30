# EventBridge rule for automated Security Hub findings alerts
# This rule automatically captures CRITICAL and HIGH severity findings from Security Hub
# and routes them to the SNS topic for notification delivery
# Note: This rule is always created (not conditional) to capture Security Hub events when Security Hub is enabled
resource "aws_cloudwatch_event_rule" "automated_alerts" {
  name        = "${var.name}-automated-trigger"
  description = "EventBridge rule for automated Security Hub findings - captures CRITICAL and HIGH severity findings for Networking, IAM, and EC2/EKS vulnerabilities"

  # Legacy callers retain the HIGH/CRITICAL filter. Opt-in routing sends all
  # active findings to a durable per-destination router, which selects Opsgenie
  # only for HIGH/CRITICAL and suppresses repeated scan updates.
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"],
    "detail" : {
      "findings" : merge({
        "RecordState" : ["ACTIVE"],
        "Workflow" : {
          "Status" : ["NEW", "NOTIFIED"]
        }
      }, local.finding_delivery_enabled ? {} : { "Severity" : { "Label" : ["CRITICAL", "HIGH"] } })
    }
  })
}

# EventBridge target for automated findings notifications via SNS (alarm_actions module)
# This target sends automated findings to the SNS topic managed by cloudwatch-alarm-actions module
# Findings are automatically forwarded to all configured notification channels (email, SMS, Slack, Teams, etc.)
resource "aws_cloudwatch_event_target" "automated_alerts_sns" {
  count = var.alarm_actions.enabled && !local.finding_delivery_enabled ? 1 : 0

  rule = aws_cloudwatch_event_rule.automated_alerts.name
  arn  = module.alarm_actions[0].topic_arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_failed_delivery[0].arn
  }

  depends_on = [
    module.alarm_actions,
    aws_sns_topic_policy.eventbridge_publish,
    aws_sqs_queue_policy.eventbridge_failed_delivery
  ]
}

resource "aws_cloudwatch_event_target" "automated_alerts_router" {
  count = local.finding_delivery_enabled ? 1 : 0

  rule = aws_cloudwatch_event_rule.automated_alerts.name
  arn  = module.finding_router[0].lambda_function_arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_failed_delivery[0].arn
  }

  depends_on = [aws_lambda_permission.finding_router_events, aws_sqs_queue_policy.eventbridge_failed_delivery]
}

# EventBridge rule for manual Security Hub action target alerts
# When a Security Hub action target is manually triggered from the console/API,
# Security Hub sends an event to EventBridge. This rule captures those manual trigger events
# and routes them to the SNS topic for notification delivery.
# Note: The event pattern may need adjustment based on actual AWS behavior.
resource "aws_cloudwatch_event_rule" "manual_alerts" {
  count = var.alarm_actions.enabled ? 1 : 0

  name        = "${var.name}-manual-trigger"
  description = "EventBridge rule for manual Security Hub action target triggers - captures manually triggered findings and routes to SNS topic"

  # Event pattern for Security Hub action target events
  # When a Security Hub action target is manually triggered from the console/API,
  # Security Hub sends events with "Security Hub Findings - Custom Action" detail-type.
  # We filter by actionName to match only events from this specific action target.
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Custom Action"],
    "detail" : {
      "actionName" : [aws_securityhub_action_target.sec-hub-target.name]
    }
  })

  depends_on = [
    aws_securityhub_action_target.sec-hub-target
  ]
}

# EventBridge target for manual action target alerts → SNS topic (alarm_actions module)
# This routes manually triggered Security Hub action target events to the SNS topic
# so they can be sent to all configured notification channels (email, SMS, Slack, Teams, etc.)
# Both automated findings (via automated_alerts rule) and manual triggers (via this rule) go to the same SNS topic
resource "aws_cloudwatch_event_target" "manual_alerts_sns" {
  count = var.alarm_actions.enabled ? 1 : 0

  rule = aws_cloudwatch_event_rule.manual_alerts[0].name
  arn  = module.alarm_actions[0].topic_arn

  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }

  dead_letter_config {
    arn = aws_sqs_queue.eventbridge_failed_delivery[0].arn
  }

  depends_on = [
    module.alarm_actions,
    aws_sns_topic_policy.eventbridge_publish,
    aws_cloudwatch_event_rule.manual_alerts,
    aws_sqs_queue_policy.eventbridge_failed_delivery
  ]
}

# EventBridge target delivery failures are distinct from later SNS subscription failures.
resource "aws_sqs_queue" "eventbridge_failed_delivery" {
  count = var.alarm_actions.enabled ? 1 : 0

  name                      = "${var.name}-eventbridge-failures"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  lifecycle {
    precondition {
      condition = (
        var.delivery_failure != null &&
        try(split(":", local.delivery_failure_escalation_topic_arn)[3], "") == data.aws_region.current.name &&
        try(split(":", local.delivery_failure_escalation_topic_arn)[4], "") == data.aws_caller_identity.current.account_id &&
        try(local.delivery_failure_escalation_topic_arn, "") != module.alarm_actions[0].topic_arn &&
        (!local.finding_delivery_enabled || length(var.alarm_actions.slack_webhooks) > 0)
      )
      error_message = "Enabled Security Hub alerting requires delivery_failure owner, a separate same-account/Region escalation topic, and a drain/replay runbook."
    }
  }
}

resource "aws_sqs_queue_policy" "eventbridge_failed_delivery" {
  count = var.alarm_actions.enabled ? 1 : 0

  queue_url = aws_sqs_queue.eventbridge_failed_delivery[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSecurityHubRuleDeliveryFailures"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.eventbridge_failed_delivery[0].arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = [aws_cloudwatch_event_rule.automated_alerts.arn, aws_cloudwatch_event_rule.manual_alerts[0].arn] }
      }
    }]
  })
}

locals {
  security_hub_delivery_failure_metrics = var.alarm_actions.enabled ? {
    for pair in setproduct(["automatic", "manual"], ["InvocationsSentToDlq", "InvocationsFailedToBeSentToDlq"]) :
    "${pair[0]}-${pair[1]}" => {
      rule_name = pair[0] == "automatic" ? aws_cloudwatch_event_rule.automated_alerts.name : aws_cloudwatch_event_rule.manual_alerts[0].name
      metric    = pair[1]
    }
  } : {}
}

resource "aws_cloudwatch_metric_alarm" "eventbridge_failed_delivery_queue_nonempty" {
  count = var.alarm_actions.enabled ? 1 : 0

  alarm_name          = "${var.name}-eventbridge-failures-queued"
  alarm_description   = "Security Hub delivery failures await investigation by ${try(var.delivery_failure.owner, "unassigned")}; ${try(var.delivery_failure.runbook_url, "missing runbook")}."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = aws_sqs_queue.eventbridge_failed_delivery[0].name }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.delivery_failure == null ? [] : [local.delivery_failure_escalation_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "eventbridge_failed_delivery_metric" {
  for_each = local.security_hub_delivery_failure_metrics

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = "Security Hub ${each.value.metric}; ${try(var.delivery_failure.owner, "unassigned")} investigates and replays via ${try(var.delivery_failure.runbook_url, "missing runbook")}."
  namespace           = "AWS/Events"
  metric_name         = each.value.metric
  dimensions          = { RuleName = each.value.rule_name }
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.delivery_failure == null ? [] : [local.delivery_failure_escalation_topic_arn]
}
