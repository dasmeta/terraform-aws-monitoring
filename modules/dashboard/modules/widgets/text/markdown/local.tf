locals {
  data = {
    "type" : "text",
    "x" : var.coordinates.x,
    "y" : var.coordinates.y,
    "width" : var.coordinates.width,
    "height" : var.coordinates.height,

    "properties" : {
      "markdown" : "${var.text}"
      "background" : var.transparent-background ? "transparent" : ""
    }
  }
}
