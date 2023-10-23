module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Traffic"

  # stats
  stat   = "Average"
  period = var.period

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  metrics = [
    { MetricName = "ProcessedBytes", color = "#D400BF" },
  ]
}
