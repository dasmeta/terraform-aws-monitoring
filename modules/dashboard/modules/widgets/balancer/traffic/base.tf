module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Traffic"

  # stats
  period = var.period

  defaults = {
    MetricNamespace   = "AWS/ApplicationELB"
    LoadBalancer      = local.balancer
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  metrics = [
    { MetricName = "ProcessedBytes", label = "ProcessedBytes Avg", color = "#D400BF", stat = "Average" },
    { MetricName = "ProcessedBytes", label = "ProcessedBytes Max", color = "#0000FF", stat = "Maximum" },
  ]
}
