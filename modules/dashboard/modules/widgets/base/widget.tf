locals {
  style_attributes = ["color"]

  region = var.region != "" ? var.region : data.aws_region.current[0].name

  # merge metrics with defaults
  metrics_with_defaults = [for metric in var.metrics : merge(var.defaults, metric)]

  # convert to list as cloudwatch expects
  metrics_raw = [for row in local.metrics_with_defaults :
    flatten([for key, item in row : key != "Style" ? [key, item] : ["Style", item]])
  ]

  # filter out Style keys as those are not needed by CloudWatch provider
  metrics = [for row in local.metrics_raw : [for item in row : item if item != "Style"]]

  data = {
    "type" : "metric",
    "x" : var.coordinates.x,
    "y" : var.coordinates.y,
    "width" : var.coordinates.width,
    "height" : var.coordinates.height,
    "properties" : {
      "title" : var.name,
      "region" : local.region,
      "metrics" : local.metrics,
      "period" : var.period,
      "stat" : var.stat
    }
  }
}
