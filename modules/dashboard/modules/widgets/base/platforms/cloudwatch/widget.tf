locals {
  common_fields         = ["MetricNamespace", "MetricName"]
  attribute_fields      = ["id", "accountId", "period", "stat", "label", "color", "yAxis", "region"]
  bool_attribute_fields = ["visible"]
  custom_fields         = ["anomaly_detection"]
  metrics_local         = var.metrics == null ? [] : var.metrics

  # merge metrics with defaults
  metrics_with_defaults = [for metric in local.metrics_local : merge(var.defaults, metric)]

  # parse metric common, dimensions and properties fields separately to join in right order (first comes common fields and then dimensions and then properties)
  metric_common = [for row in local.metrics_with_defaults : [for field in local.common_fields : try(row[field], "NoDataSet")]]
  dimensions    = [for row in local.metrics_with_defaults : flatten([for key, item in row : [key, item] if !contains(concat(local.common_fields, local.attribute_fields, local.bool_attribute_fields, local.custom_fields), key)])]

  attributes = [for index, row in local.metrics_with_defaults : merge(
    { id = "m${index + 1}" },
    { for field in local.attribute_fields : field => row[field] if try(row[field], null) != null },
    { for field in local.bool_attribute_fields : field => tobool(row[field]) if try(row[field], null) != null }
  )]
  metric_properties = [for index, row in local.metrics_with_defaults : (length(keys(local.attributes[index])) > 0 ? [local.attributes[index]] : [])]

  # concat parsed fields to have list as cloudwatch expects
  metrics = [for index, row in local.metrics_with_defaults : concat(local.metric_common[index], local.dimensions[index], local.metric_properties[index])]
  anomaly_detection_metrics = [for index, row in local.metrics_with_defaults : try(row.anomaly_detection, false) ? [{
    expression = "ANOMALY_DETECTION_BAND(m${index + 1}, 2)"
    id         = "ad${index + 1}"
    label      = "anomaly_detection (${row.MetricName})"
  }] : [] if try(row.anomaly_detection, false)]


  query_with_sources = var.query == null ? null : "${join(" | ", [for source in var.sources : "SOURCE '${source}'"])} | ${var.query}"

  expression_metrics = [for index, row in var.expressions : [merge(
    { for key, value in row : key => value if value != null },
    {
      id    = "e${index + 1}",
      label = coalesce(row.label, row.expression)
    }
  )]]

  // common properties
  properties = {
    title                    = var.name
    region                   = var.region
    query                    = local.query_with_sources
    view                     = var.view
    stacked                  = var.stacked
    alarms                   = var.alarms
    type                     = var.properties_type
    annotations              = var.annotations
    metrics                  = var.type != "metric" || var.metrics == null ? null : concat(local.metrics, local.anomaly_detection_metrics, local.expression_metrics)
    period                   = var.type != "metric" ? null : var.period
    stat                     = var.type != "metric" ? null : var.stat
    yAxis                    = var.type != "metric" ? null : var.yAxis
    setPeriodToTimeRange     = var.setPeriodToTimeRange
    singleValueFullPrecision = var.singleValueFullPrecision
    sparkline                = var.sparkline
    start                    = var.start
    trend                    = var.trend
    end                      = var.end
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
