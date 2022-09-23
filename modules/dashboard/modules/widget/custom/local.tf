locals {
  widget_data_metric = [for item in var.custom_metric : {
    "type" : "metric",
    "x" : item.key * item.width,
    "y" : item.rows,
    "width" : item.width,
    "height" : item.height,
    "properties" : {
      "metrics" : item.metrics,
      "period" : item.period,
      "stat" : item.stat,
      "region" : item.region,
      "title" : "${item.name}"
    }
  }]
}
