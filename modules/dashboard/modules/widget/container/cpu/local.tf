data "aws_region" "current" {}

// pod_cpu_utilization_over_pod_limit ?
locals {
  widget_data_metric = [for item in var.cpu : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["ContainerInsights", "pod_cpu_utilization", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]],
        ["ContainerInsights", "pod_cpu_reserved_capacity", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"], { "color" : "#d62728" }]
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Average",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
