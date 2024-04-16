module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Response Time"

  # stats
  stat   = "Maximum"
  period = var.period

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  metrics = [
    { MetricName = "TargetResponseTime", color = "#56F2D6" },
  ]
}
