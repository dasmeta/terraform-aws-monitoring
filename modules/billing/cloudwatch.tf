locals {
  actions = concat(
    aws_sns_topic.alerts_notify_email.*.arn,
    aws_sns_topic.alerts_notify_sms.*.arn,
    aws_sns_topic.alerts_notify_opsgenie.*.arn
  )
}

resource "aws_cloudwatch_metric_alarm" "billing" {
  count = length(var.alarm_name)

  alarm_name          = var.alarm_name
  comparison_operator = var.comparison_operator_billing
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
