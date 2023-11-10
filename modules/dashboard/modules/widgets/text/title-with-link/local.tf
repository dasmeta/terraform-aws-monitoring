locals {
  data = {
    "type" : "text",
    "x" : 0,
    "y" : var.y,
    "width" : var.width,
    "height" : 1,

    "properties" : {
      "markdown" : "## [${var.text}](${var.link_to_jump})"
      "background" : "transparent"
    }
  }
}
