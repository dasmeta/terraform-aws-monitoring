locals {
  data = {
    "type" : "metric",
    "x" : var.coordinates.x,
    "y" : var.coordinates.y,
    "width" : var.coordinates.width,
    "height" : var.coordinates.height,
    "properties" : {
      "title" : var.name,
      "region" : var.region == "" ? data.aws_region.current.name : var.region,
      "metrics" : var.metrics,
      "period" : var.period,
      "stat" : var.stat
    }
  }
}
