resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  for_each = {
    for key, cfg in local.canary_configs : key => cfg
    if cfg.alarm_config.enabled
  }

  alarm_name          = local.alarm_names[each.key]
  alarm_description   = "CloudWatch Synthetics canary ${local.canary_names[each.key]} success below threshold."
  comparison_operator = each.value.alarm_config.comparison_operator
  evaluation_periods  = each.value.alarm_config.evaluation_periods
  datapoints_to_alarm = each.value.alarm_config.datapoints_to_alarm
  threshold           = each.value.alarm_config.threshold
  treat_missing_data  = each.value.alarm_config.treat_missing_data

  namespace   = "CloudWatchSynthetics"
  metric_name = "Success"
  period      = each.value.alarm_config.period
  statistic   = "Minimum"

  dimensions = {
    CanaryName = aws_synthetics_canary.this[each.key].name
  }

  alarm_actions = [var.sns_topic_arn]

  tags = merge(var.default_tags, var.canaries[each.key].tags, {
    Name = local.alarm_names[each.key]
  })

  depends_on = [aws_synthetics_canary.this]
}
