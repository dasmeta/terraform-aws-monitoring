
data "aws_region" "current" {}

locals {
  y    = 1
  y_y  = 3
  x    = 0
  x_x  = 8
  x_xx = 16
  widget_data_metric = [for k, item in var.widget : {
    "type" : "metric",
    "x" : k % 3 == 0 ? local.x_xx : k % 2 == 0 ? local.x_x : local.x,
    "y" : k % 3 == 0 ? local.y * k * 2 : local.y,
    "width" : 8,
    "height" : 5,
    "properties" : {
      "metrics" : [
        split("/", item.source)
      ],
      "period" : item.period,
      "stat" : item.statistic,
      "region" : data.aws_region.current.name,
      "title" : item.name
    }
  } if item.type == "metric"]

  widget_data_text = [for k, item in var.widget : {
    "type" : "text",
    "x" : 0,
    "y" : 0,
    "width" : 24,
    "height" : 1,
    "properties" : {
      "markdown" : item.markdown
    }
  } if item.type == "text"]
}

output "widget" {
  value = concat(local.widget_data_metric, local.widget_data_text)
}

output "widget_data_text" {
  value = local.widget_data_text
}
