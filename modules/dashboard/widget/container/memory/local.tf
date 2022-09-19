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
        ["ContainerInsights", "pod_memory_reserved_capacity", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]]
      ],
      "period" : var.default["period"],
      "stat" : "Sum",
      "region" : data.aws_region.current.name,
      "title" : "${item.container} Memory"
    }
  }]
}
