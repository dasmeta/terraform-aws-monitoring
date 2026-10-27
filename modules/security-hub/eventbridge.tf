# EventBridge rule for automated Security Hub findings alerts
# This rule automatically captures CRITICAL and HIGH severity findings from Security Hub
# and routes them to the SNS topic for notification delivery
# Note: This rule is always created (not conditional) to capture Security Hub events when Security Hub is enabled
resource "aws_cloudwatch_event_rule" "automated_alerts" {
  name        = "${var.name}-automated-trigger"
  description = "EventBridge rule for automated Security Hub findings - captures CRITICAL and HIGH severity findings for Networking, IAM, and EC2/EKS vulnerabilities"

  # Filter for CRITICAL and HIGH severity findings
  # Note: Additional filtering by product name or finding type can be done in Lambda functions
  # The event pattern filters by severity which is the primary concern for alerting
  # RecordState filter ensures we only alert on ACTIVE findings (not ARCHIVED/resolved ones)
  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"],
    "detail" : {
      "findings" : {
        "RecordState" : ["ACTIVE"],
        "Workflow" : {
          "Status" : ["NEW", "NOTIFIED"]
        },
        "Severity" : {
          "Label" : ["CRITICAL", "HIGH"]
        }
      }
    }
  })
}

# EventBridge target for automated findings notifications via SNS (alarm_actions module)
# This target sends automated findings to the SNS topic managed by cloudwatch-alarm-actions module
# Findings are automatically forwarded to all configured notification channels (email, SMS, Slack, Teams, etc.)
resource "aws_cloudwatch_event_target" "automated_alerts_sns" {
  count = var.alarm_actions.enabled ? 1 : 0

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
        ArnEquals    = { "aws:SourceArn" = [aws_cloudwatch_event_rule.automated_alerts.arn, aws_cloudwatch_event_rule.manual_alerts[0].arn] }
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
}
