locals {
  common_fields    = ["MetricNamespace", "MetricName"]
  attribute_fields = ["accountId", "period", "stat", "label", "visible", "color", "yAxis"]
  custom_fields    = ["anomaly_detection"]
  metrics_local    = var.metrics == null ? [] : var.metrics

  # merge metrics with defaults
  metrics_with_defaults = [for metric in local.metrics_local : merge(var.defaults, metric)]

  # parse metric common, dimensions and properties fields separately to join in right order (first comes common fields and then dimensions and then properties)
  metric_common = [for row in local.metrics_with_defaults : [for field in local.common_fields : try(row[field], "NoDataSet")]]
  dimensions    = [for row in local.metrics_with_defaults : flatten([for key, item in row : [key, item] if !contains(concat(local.common_fields, local.attribute_fields, local.custom_fields), key)])]

  custom_attributes = [for index, row in local.metrics_with_defaults : try(row.anomaly_detection, false) ? { id = "m${index + 1}" } : {}]
  attributes        = [for index, row in local.metrics_with_defaults : merge({ for field in local.attribute_fields : field => try(row[field], null) if try(row[field], null) != null }, local.custom_attributes[index])]
  metric_properties = [for index, row in local.metrics_with_defaults : (length(keys(local.attributes[index])) > 0 ? [local.attributes[index]] : [])]

  # concat parsed fields to have list as cloudwatch expects
  metrics = [for index, row in local.metrics_with_defaults : concat(local.metric_common[index], local.dimensions[index], local.metric_properties[index])]
  anomaly_detection_metrics = [for index, row in local.metrics_with_defaults : try(row.anomaly_detection, false) ? [{
    expression = "ANOMALY_DETECTION_BAND(m${index + 1}, 2)"
    id         = "e${index + 1}"
    label      = "anomaly_detection (${row.MetricName})"
  }] : [] if try(row.anomaly_detection, false)]


  query_with_sources = var.query == null ? null : "${join(" | ", [for source in var.sources : "SOURCE '${source}'"])} | ${var.query}"

  // common properties
  properties = {
    title       = var.name
    region      = var.region
    query       = local.query_with_sources
    view        = var.view
    stacked     = var.stacked
    alarms      = var.alarms
    type        = var.properties_type
    annotations = var.annotations
    metrics     = var.type != "metric" || var.metrics == null ? null : concat(local.metrics, local.anomaly_detection_metrics)
    period      = var.type != "metric" ? null : var.period
    stat        = var.type != "metric" ? null : var.stat
    yAxis       = var.type != "metric" ? null : { left = { min = 0 } }
  }

  data = {
    type       = var.type
    x          = var.coordinates.x
    y          = var.coordinates.y
    width      = var.coordinates.width
    height     = var.coordinates.height
    properties = { for key, value in local.properties : key => value if value != null } # filter out props with null values
  }
}
