module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "4XX (${var.balancer})"

  defaults = {
    "LoadBalancer" : local.balancer
  }

  metrics = [
    # { "AWS/ApplicationELB" : "RequestCount" },
    { "AWS/ApplicationELB" : "HTTPCode_Target_4XX_Count", "Style" : { "color" : "#ff7f0e" } },
    { "AWS/ApplicationELB" : "HTTPCode_ELB_4XX_Count", "Style" : { "color" : "#ffbb78" } }
  ]
}
