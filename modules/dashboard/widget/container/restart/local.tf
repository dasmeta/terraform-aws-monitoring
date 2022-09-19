data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.restart : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["ContainerInsights", "pod_number_of_container_restarts", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"]],
        # { "color": "#1f77b4" }
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Sum",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.container} Restart"
    }
  }]
}
