module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Requests (${var.balancer})"

  defaults = {
    "LoadBalancer" : local.balancer
  }

  metrics = [
    { "AWS/ApplicationELB" : "RequestCount" },
    { "AWS/ApplicationELB" : "HTTPCode_Target_2XX_Count", "Style" : { "color" : "#2ca02c" } },
    { "AWS/ApplicationELB" : "HTTPCode_ELB_2XX_Count", "Style" : { "color" : "#98df8a" } }
  ]
}
