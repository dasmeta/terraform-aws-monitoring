data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.traffic_5xx : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${item.loadbalancer}"],
        ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#d62728" }],
        ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${item.loadbalancer}", { "color" : "#ff9896" }],
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Sum",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.name}"
    }
  }]
}
