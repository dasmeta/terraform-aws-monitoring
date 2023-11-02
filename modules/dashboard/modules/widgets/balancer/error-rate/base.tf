module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Error Rate"

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
    { id = "m2", MetricName = "HTTPCode_Target_2XX_Count", color = "#3ECE76", visible = false },
    { id = "m5", MetricName = "HTTPCode_Target_5XX_Count", color = "#FF0F3C", visible = false, anomaly_detection = false },
  ]

  expressions = [
    {
      id         = "m1",
      expression = "m5/m2*100"
      label      = "Percentage"
      color      = "#FF103B"
    }
  ]
}
