module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "All Requests"

  stat = "Sum"

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    LoadBalancer    = local.balancer
    TargetGroup     = local.target_group
  }

  period = var.period

  metrics = [
    { MetricName = "HTTPCode_Target_2XX_Count", color = "#3ECE76" },
    { MetricName = "HTTPCode_Target_3XX_Count", color = "#FFC300" },
    { MetricName = "HTTPCode_Target_4XX_Count", color = "#FF774D" },
    { MetricName = "HTTPCode_Target_5XX_Count", color = "#FF0F3C" },
  ]
}
