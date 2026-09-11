resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  for_each = {
    for key, cfg in local.canary_configs : key => cfg
    if cfg.alarm_config.enabled
  }

  alarm_name          = local.alarm_names[each.key]
  alarm_description   = "CloudWatch Synthetics canary ${local.canary_names[each.key]} recorded one or more failed runs."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = each.value.alarm_config.evaluation_periods
  datapoints_to_alarm = each.value.alarm_config.datapoints_to_alarm
  threshold           = 1
  treat_missing_data  = each.value.alarm_config.treat_missing_data

  namespace   = "CloudWatchSynthetics"
  metric_name = "Failed"
  period      = each.value.alarm_config.period
  statistic   = "Sum"

  dimensions = {
    CanaryName = aws_synthetics_canary.this[each.key].name
  }

  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.default_tags, var.canaries[each.key].tags, {
    Name = local.alarm_names[each.key]
  })
}
