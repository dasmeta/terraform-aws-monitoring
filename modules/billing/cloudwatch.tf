locals {
  actions = concat(
    aws_sns_topic.alerts-notify-email.*.arn,
    aws_sns_topic.alerts-notify-sms.*.arn,
    aws_sns_topic.alerts-notify-opsgenie.*.arn
  )
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  count = length(var.metric_alarm_billing.alarm_name)
  alarm_name          = var.metric_alarm_billing.alarm_name
  comparison_operator = var.metric_alarm_billing.comparison_operator-billing
  evaluation_periods  = var.metric_alarm_billing.evaluation_periods
  metric_name         = var.metric_alarm_billing.metric_name
  namespace           = var.metric_alarm_billing.namespace
  period              = var.metric_alarm_billing.period
  statistic           = var.metric_alarm_billing.statistic
  threshold           = var.metric_alarm_billing.threshold
  alarm_actions       = local.actions

  dimensions = {
    Currency = var.notification.threshold_type
  }
}
