data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.disk : {
    "type" : "metric",
    "x" : item.key * var.default["width"],
    "y" : item.rows,
    "width" : var.default["width"],
    "height" : var.default["height"],
    "properties" : {
      "metrics" : [
        # split("/", item.source)
      ],
      "period" : var.default["period"],
      "stat" : "Sum",
      "region" : data.aws_region.current.name,
      "title" : "${item.container} Disk"
    }
  }]
}
