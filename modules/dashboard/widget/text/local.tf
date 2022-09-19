data "aws_region" "current" {}

locals {
  widget_data_metric = [for item in var.text : {
    "type" : "text",
    "x" : item.key,
    "y" : item.rows,
    "width" : 24,
    "height" : 1,
    "properties" : {
      "markdown" : item.content
    }
  }]
}
