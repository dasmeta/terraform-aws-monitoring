locals {

  health_check_alerts = flatten([
    for health_check in var.health_checks : [
      {
        name               = "${health_check.host}:${health_check.port}${health_check.path}-Main"
        description        = "Main monitoring for ${health_check.host}"
        source             = "AWS/Route53/HealthCheckStatus"
        filters            = { Host = health_check.host }
        statistic          = try(health_check.main.statistic, "min")
        equation           = try(health_check.main.equation, "lt")
        threshold          = try(health_check.main.threshold, 1)
        period             = try(health_check.main.period, 60)
        treat_missing_data = "breaching"
      },
      {
        name               = "${health_check.host}:${health_check.port}${health_check.path}-Percentage"
        description        = "Percentage monitoring for ${health_check.host}"
        source             = "AWS/Route53/HealthCheckPercentageHealthy"
        filters            = { Host = health_check.host }
        statistic          = try(health_check.percentage.statistic, "avg")
        equation           = try(health_check.percentage.equation, "lt")
        threshold          = try(health_check.percentage.threshold, 75)
        period             = try(health_check.percentage.period, 60)
        treat_missing_data = "breaching"
      }
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
