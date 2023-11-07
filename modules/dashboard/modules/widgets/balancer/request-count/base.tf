module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Request Count"

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
    { MetricName = "RequestCount", color = "#127CEF" },
  ]
}
