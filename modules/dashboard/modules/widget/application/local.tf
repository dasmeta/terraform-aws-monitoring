data "aws_region" "current" {}

// pod_cpu_utilization_over_pod_limit ?
locals {
  widget_data_metric = [for item in var.application : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["ContainerInsights/Prometheus", item.metric_name, "app", item.app, "container_name", item.container_name, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]]
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Average",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
