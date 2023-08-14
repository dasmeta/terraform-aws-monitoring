locals {
  health_checks = [for health_check in var.health_checks : {
    host              = health_check.host
    port              = try(health_check.port, 443)
    type              = try(health_check.type, "HTTPS")
    path              = try(health_check.path, "/")
    failure_threshold = try(health_check.failure_threshold, "5")
    request_interval  = try(health_check.request_interval, "30")
    measure_latency   = try(health_check.measure_latency, false)
    regions           = try(health_check.regions, ["us-west-1", "us-west-2", "us-east-1", "eu-west-1", "sa-east-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1"])
    region            = try(health_check.region, "us-east-1") //data.aws_region.project.name)
    tags              = try(health_check.tags, {})
  } if try(health_check.host, null) != null]

  health_check_alerts = [for key, health_check in aws_route53_health_check.health_checks : {
    name               = key
    description        = "Monitoring ${health_check.fqdn}:${health_check.port}${health_check.resource_path}"
    source             = "AWS/Route53/HealthCheckStatus"
    filters            = { HealthCheckId = health_check.id }
    statistic          = "min"
    equation           = "lt"
    threshold          = "1"
    period             = "60"
    treat_missing_data = "breaching"
  }]

  comparison_operators = {
    gte : "GreaterThanOrEqualToThreshold",
    gt : "GreaterThanThreshold",
    lt : "LessThanThreshold",
    lte : "LessThanOrEqualToThreshold",
    ltlgtu : "LessThanLowerOrGreaterThanUpperThreshold",
    ltl : "LessThanLowerThreshold",
    gtu : "GreaterThanUpperThreshold"
  }

  statistics = {
    max : "Maximum",
    min : "Minimum",
    sum : "Sum",
    avg : "Average",
    count : "SampleCount"
  }

  alarm_actions = [
    "arn:aws:sns:${data.aws_region.project.name}:${data.aws_caller_identity.project.account_id}:${var.sns_topic}"
  ]
  ok_actions = [
    "arn:aws:sns:${data.aws_region.project.name}:${data.aws_caller_identity.project.account_id}:${var.sns_topic}"
  ]
}
