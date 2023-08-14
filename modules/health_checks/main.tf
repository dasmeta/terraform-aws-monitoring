resource "aws_route53_health_check" "health_checks" {
  for_each = { for health_check in local.health_checks : "${health_check.host}:${health_check.port}${health_check.path}" => health_check }

  fqdn                    = each.value.host
  port                    = each.value.port
  type                    = each.value.type
  resource_path           = each.value.path
  failure_threshold       = each.value.failure_threshold
  request_interval        = each.value.request_interval
  reference_name          = substr(each.key, 0, 27)
  measure_latency         = each.value.measure_latency
  regions                 = each.value.regions
  cloudwatch_alarm_region = each.value.region
  tags                    = merge({ Name = each.key }, each.value.tags)
}


module "external_health_check-alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "4.3.0"

  for_each = { for alert in local.health_check_alerts : "${alert.source}-${alert.name}" => alert }

  alarm_name          = each.value.name //replace(lower(each.value.name), " ", "-")
  alarm_description   = each.value.description
  comparison_operator = local.comparison_operators[each.value.equation]
  evaluation_periods  = 1
  threshold           = each.value.threshold
  treat_missing_data  = each.value.treat_missing_data != null ? each.value.treat_missing_data : "missing"
  dimensions          = each.value.filters
  metric_name         = length(split("/", each.value.source)) == 3 ? split("/", each.value.source)[2] : split("/", each.value.source)[1]
  namespace           = length(split("/", each.value.source)) == 3 ? format("%s/%s", split("/", each.value.source)[0], split("/", each.value.source)[1]) : split("/", each.value.source)[0]
  period              = each.value.period
  statistic           = local.statistics[each.value.statistic]

  alarm_actions             = local.alarm_actions
  ok_actions                = local.ok_actions
  insufficient_data_actions = local.alarm_actions
}
