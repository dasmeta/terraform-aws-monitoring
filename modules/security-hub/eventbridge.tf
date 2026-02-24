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

  depends_on = [
    module.alarm_actions
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

  depends_on = [
    module.alarm_actions,
    aws_cloudwatch_event_rule.manual_alerts
  ]
}
