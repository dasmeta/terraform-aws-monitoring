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
  }

  metrics = [
    { MetricName = "TargetResponseTime", color = "#e377c2" },
  ]
}
