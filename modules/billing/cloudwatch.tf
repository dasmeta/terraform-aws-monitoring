locals {
  actions = concat(
    aws_sns_topic.alerts-notify-email.*.arn,
    aws_sns_topic.alerts-notify-sms.*.arn,
    aws_sns_topic.alerts-notify-opsgenie.*.arn
  )
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  count = length(var.account_budget_limit) > 0 ? 1 : 0
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_actions       = local.actions

  dimensions = {
    Currency = var.threshold_type
  }
}
