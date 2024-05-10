locals {

  health_check_alerts = flatten([
    for aws_hc in aws_route53_health_check.health_checks : [
      for var_hc in local.health_checks :
      aws_hc.fqdn == var_hc.host && tostring(aws_hc.port) == tostring(var_hc.port) && aws_hc.resource_path == var_hc.path ?
      [
        {
          name               = "${var_hc.host}:${var_hc.port}${var_hc.path}-Main"
          description        = "Main monitoring for ${var_hc.host}"
          source             = "AWS/Route53/HealthCheckStatus"
          filters            = { HealthCheckId = aws_hc.id }
          statistic          = try(var_hc.main.statistic, "min")
          equation           = try(var_hc.main.equation, "lt")
          threshold          = try(var_hc.main.threshold, 1)
          period             = try(var_hc.main.period, 60)
          treat_missing_data = "breaching"
        },
        {
          name               = "${var_hc.host}:${var_hc.port}${var_hc.path}-Percentage"
          description        = "Percentage monitoring for ${var_hc.host}"
          source             = "AWS/Route53/HealthCheckPercentageHealthy"
          filters            = { HealthCheckId = aws_hc.id }
          statistic          = try(var_hc.percentage.statistic, "avg")
          equation           = try(var_hc.percentage.equation, "lt")
          threshold          = try(var_hc.percentage.threshold, 75)
          period             = try(var_hc.percentage.period, 60)
          treat_missing_data = "breaching"
        }
      ] : []
    ]
  ])

  health_checks = [for health_check in var.health_checks : {
    host              = health_check.host
    port              = try(health_check.port, 443)
    type              = try(health_check.type, "HTTPS")
    path              = try(health_check.path, "/")
    failure_threshold = try(health_check.failure_threshold, "1")
    request_interval  = try(health_check.request_interval, "30")
    measure_latency   = try(health_check.measure_latency, false)
    regions           = try(health_check.regions, ["us-west-1", "us-east-1", "eu-west-1"])
    region            = try(health_check.region, data.aws_region.project.name)
    tags              = try(health_check.tags, {})
  } if try(health_check.host, null) != null]
}

resource "aws_route53_health_check" "health_checks" {
  for_each = {
    for health_check in local.health_checks :
    "${health_check.host}:${health_check.port}${health_check.path}" => health_check
  }

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
