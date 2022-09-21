data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.memory : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["ContainerInsights", "pod_memory_utilization", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]],
        ["ContainerInsights", "pod_memory_reserved_capacity", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"], { "color" : "#d62728" }]
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Average",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
