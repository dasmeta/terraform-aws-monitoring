locals {
  region           = var.region != "" ? var.region : data.aws_region.current[0].name
  common_fields    = ["MetricNamespace", "MetricName"]
  attribute_fields = ["accountId", "period", "stat", "label", "visible", "color", "yAxis"]
  custom_fields    = ["anomaly_detection"]

  # merge metrics with defaults
  metrics_with_defaults = [for metric in var.metrics : merge(var.defaults, metric)]

  # parse metric common, dimensions and properties fields separately to join in right order (first comes common fields and then dimensions and then properties)
  metric_common = [for row in local.metrics_with_defaults : [for field in local.common_fields : try(row[field], "NoDataSet")]]
  dimensions    = [for row in local.metrics_with_defaults : flatten([for key, item in row : [key, item] if !contains(concat(local.common_fields, local.attribute_fields, local.custom_fields), key)])]

  custom_attributes = [for index, row in local.metrics_with_defaults : try(row.anomaly_detection, false) ? { id = "m${index + 1}" } : {}]
  attributes        = [for index, row in local.metrics_with_defaults : merge({ for field in local.attribute_fields : field => try(row[field], null) if try(row[field], null) != null }, local.custom_attributes[index])]
  properties        = [for index, row in local.metrics_with_defaults : (length(keys(local.attributes[index])) > 0 ? [local.attributes[index]] : [])]

  # concat parsed fields to have list as cloudwatch expects
  metrics = [for index, row in local.metrics_with_defaults : concat(local.metric_common[index], local.dimensions[index], local.properties[index])]
  anomaly_detection_metrics = [for index, row in local.metrics_with_defaults : try(row.anomaly_detection, false) ? [{
    expression = "ANOMALY_DETECTION_BAND(m${index + 1}, 2)"
    id         = "e${index + 1}"
    label      = "anomaly_detection (${row.MetricName})"
  }] : [] if try(row.anomaly_detection, false)]

  data = {
    type   = "metric"
    x      = var.coordinates.x
    y      = var.coordinates.y
    width  = var.coordinates.width
    height = var.coordinates.height
    properties = {
      title   = var.name
      region  = local.region
      metrics = concat(local.metrics, local.anomaly_detection_metrics)
      period  = var.period
      stat    = var.stat
    }
  }
}
