data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.traffic_4xx : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${item.loadbalancer}"],
        ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ff7f0e" }],
        ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ffbb78" }],
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Sum",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
