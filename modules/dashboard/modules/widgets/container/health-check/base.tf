module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Health Check"

  stat = "Average"

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    TargetGroup       = local.target_group
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  period = var.period

  metrics = [
    { MetricName = "HealthyHostCount", color = "#3ECE76" },
    { MetricName = "UnHealthyHostCount", color = "#FF0F3C" },
  ]
}
