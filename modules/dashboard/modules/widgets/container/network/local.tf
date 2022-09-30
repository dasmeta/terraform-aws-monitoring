data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.network : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["ContainerInsights", "pod_network_rx_bytes", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"], { "color" : "#17becf" }],
        ["ContainerInsights", "pod_network_tx_bytes", "PodName", item.container, "ClusterName", var.default["clustername"], "Namespace", var.default["namespace"], { "color" : "#e377c2" }]
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Average",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
