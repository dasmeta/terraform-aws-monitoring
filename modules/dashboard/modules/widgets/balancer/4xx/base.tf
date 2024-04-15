module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "4XX"

  # stats
  stat   = "Sum"
  period = var.period

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  metrics = [
    { MetricName = "HTTPCode_Target_4XX_Count", "color" = "#ff7f0e" },
  ]
}
