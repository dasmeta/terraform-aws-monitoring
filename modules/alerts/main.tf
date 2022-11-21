locals {
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

  alert                = [for alert in var.alerts : alert if alert.log_based_metric != true && alert.anomaly_detection == false]
  alert_w_anomalydetec = [for alert in var.alerts : alert if alert.log_based_metric != true && alert.anomaly_detection != false]
  log_based_alert      = [for alert in var.alerts : alert if alert.log_based_metric == true]

  alarm_actions = [
    "arn:aws:sns:${data.aws_region.project.name}:${data.aws_caller_identity.project.account_id}:${var.sns_topic}"
  ]
}

module "cloudwatch_metric-alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.3.0"

  for_each = { for alert in local.alert : "${alert.name}-${alert.source}" => alert }

  alarm_name          = each.value.name // replace(lower(each.value.name), " ", "-")
  comparison_operator = local.comparison_operators[each.value.equation]
  evaluation_periods  = 1
  threshold_metric_id = each.value.anomaly_detection ? "e1" : null
  threshold           = each.value.anomaly_detection ? null : each.value.threshold
  treat_missing_data  = each.value.treat_missing_data != null ? each.value.treat_missing_data : "missing"

  metric_query = concat([
    {
      id          = "m1"
      return_data = true

      account_id = each.value.account_id == null ? data.aws_caller_identity.project.account_id : each.value.account_id

      metric = [{
        dimensions  = each.value.filters
        metric_name = length(split("/", each.value.source)) == 3 ? split("/", each.value.source)[2] : split("/", each.value.source)[1]
        namespace   = length(split("/", each.value.source)) == 3 ? format("%s/%s", split("/", each.value.source)[0], split("/", each.value.source)[1]) : split("/", each.value.source)[0]
        period      = each.value.period
        stat        = local.statistics[each.value.statistic]
      }]
    }]
  )

  alarm_actions             = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}


# This module usage is more a hack, because anomaly detection only works on metrics
# in the same AWS account. So alerts with anomaly detection need to be created in the AWS
# account where the metrics are. This will probably lead to confusion, but a technical limitation.
module "cloudwatch_metric-alarm_with_anomalydetection" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.3.0"

  for_each = { for alert in local.alert_w_anomalydetec : "${alert.name}-${alert.source}" => alert }

  alarm_name          = each.value.name // replace(lower(each.value.name), " ", "-")
  comparison_operator = local.comparison_operators[each.value.equation]
  evaluation_periods  = 1
  threshold_metric_id = each.value.anomaly_detection ? "e1" : null
  threshold           = each.value.anomaly_detection ? null : each.value.threshold
  treat_missing_data  = each.value.treat_missing_data != null ? each.value.treat_missing_data : "missing"

  metric_query = concat([
    {
      id          = "m1"
      return_data = true

      account_id = each.value.account_id == null ? data.aws_caller_identity.project.account_id : each.value.account_id

      metric = [{
        dimensions  = each.value.filters
        metric_name = length(split("/", each.value.source)) == 3 ? split("/", each.value.source)[2] : split("/", each.value.source)[1]
        namespace   = length(split("/", each.value.source)) == 3 ? format("%s/%s", split("/", each.value.source)[0], split("/", each.value.source)[1]) : split("/", each.value.source)[0]
        period      = each.value.period
        stat        = local.statistics[each.value.statistic]
      }]
    }],
    [{
      id          = "e1"
      expression  = "ANOMALY_DETECTION_BAND(m1)"
      return_data = true
    }]
  )

  alarm_actions             = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

module "cloudwatch_log-based-metric-alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.3.0"

  for_each = { for alert in local.log_based_alert : "${alert.source}-${alert.name}" => alert }

  alarm_name          = each.value.name // replace(lower(each.value.name), " ", "-")
  comparison_operator = local.comparison_operators[each.value.equation]
  evaluation_periods  = 1
  threshold_metric_id = each.value.anomaly_detection ? "e1" : null
  threshold           = each.value.anomaly_detection ? null : each.value.threshold
  treat_missing_data  = each.value.treat_missing_data == null ? "notBreaching" : each.value.treat_missing_data

  metric_query = concat([
    {
      id          = "m1"
      return_data = true

      metric = [{
        dimensions  = each.value.filters
        metric_name = split("/", each.value.source)[1]
        namespace   = format("%s/%s", split("/", each.value.source)[0], data.aws_caller_identity.project.account_id)
        period      = each.value.period
        stat        = local.statistics[each.value.statistic]
      }]
    }],
    each.value.anomaly_detection ?
    [{
      id          = "e1"
      expression  = "ANOMALY_DETECTION_BAND(m1)"
      return_data = true
    }] : []
  )

  alarm_actions             = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}


module "external_health_check-alarms" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.3.0"

  for_each = { for alert in local.health_check_alerts : "${alert.source}-${alert.name}" => alert }

  alarm_name          = each.value.name //replace(lower(each.value.name), " ", "-")
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
  insufficient_data_actions = local.alarm_actions
}
