locals {
  data = {
    "type" : "text",
    "x" : 0,
    "y" : var.y,
    "width" : 24,
    "height" : 1,

    "properties" : {
      "markdown" : "# ${var.text}"
    }
  }
}
