data "aws_region" "current" {}
// pod_cpu_reserved_capacity, 
// pod_cpu_utilization
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
        ["ContainerInsights", "pod_cpu_reserved_capacity", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]]
      ],
      "period" : var.default["period"],
      "stat" : "Sum",
      "region" : data.aws_region.current.name,
      "title" : "${item.container} CPU"
    }
  }]
}
