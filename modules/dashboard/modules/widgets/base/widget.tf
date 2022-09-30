locals {
  data = {
    "type" : "metric",
    "x" : var.x,
    "y" : var.y,
    "width" : var.width,
    "height" : var.height,
    "properties" : {
      "title" : var.name,
      "region" : var.region == "" ? data.aws_region.current.name : var.region,
      "metrics" : var.metrics,
      "period" : var.period,
      "stat" : var.stat
    }
  }
}
