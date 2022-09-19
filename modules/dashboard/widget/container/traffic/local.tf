data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.traffic : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        # split("/", item.source)
      ],
      "period" : item.period == 0 ? var.default["period"] : item.period,
      "stat" : "Sum",
      "region" : "${item.region == "" ? data.aws_region.current.name : item.region}",
      "title" : "${item.container} Traffic"
    }
  }]
}
