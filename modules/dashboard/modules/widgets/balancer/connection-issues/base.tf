module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "ALB to Target Connection Issues"

  # stats
  stat   = "Sum"
  period = var.period

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  metrics = [
    { id = "m5t", MetricName = "HTTPCode_Target_5XX_Count", color = "#3ECE76", visible = false },
    { id = "m5e", MetricName = "HTTPCode_ELB_5XX_Count", color = "#FF774D", visible = false, anomaly_detection = false },
  ]

  expressions = [
    {
      id         = "m1",
      expression = "m5t/m5e"
      label      = "ALB vs Target"
      color      = "#FF0F3C"
    }
  ]
}
