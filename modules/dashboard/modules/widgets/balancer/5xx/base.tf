module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "5XX (${var.balancer})"

  defaults = {
    "LoadBalancer" : local.balancer
  }

  metrics = [
    # { "AWS/ApplicationELB" : "RequestCount" },
    { "AWS/ApplicationELB" : "HTTPCode_Target_5XX_Count", "Style" : { "color" : "#d62728" } },
    { "AWS/ApplicationELB" : "HTTPCode_ELB_5XX_Count", "Style" : { "color" : "#ff9896" } },
  ]
}
