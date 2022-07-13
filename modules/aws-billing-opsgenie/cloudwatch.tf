resource "aws_cloudwatch_metric_alarm" "billing" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_actions       = ["${aws_sns_topic.billing_alarm_topic.arn}"]

  dimensions = {
    Currency = var.threshold_type
  }
}