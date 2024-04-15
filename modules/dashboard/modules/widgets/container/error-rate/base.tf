module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Error Rate"

  stat = "Sum"

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    TargetGroup       = local.target_group
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  period = var.period

  metrics = [
    { id = "m2", MetricName = "HTTPCode_Target_2XX_Count", visible = false },
    { id = "m5", MetricName = "HTTPCode_Target_5XX_Count", visible = false },
  ]

  expressions = [
    {
      expression = "m5/m2*100"
      label      = "Percentage"
      color      = "#FF103B"
    }
  ]
}
