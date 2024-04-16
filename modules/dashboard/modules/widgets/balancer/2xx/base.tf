module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "2XX"

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
    { MetricName : "RequestCount" },
    { MetricName : "HTTPCode_Target_2XX_Count", "color" = "#2ca02c" },
  ]
}
