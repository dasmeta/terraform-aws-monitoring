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
  }

  metrics = [
    # { MetricName = "RequestCount" },
    { MetricName = "HTTPCode_Target_4XX_Count", "color" = "#ff7f0e" },
    # { MetricName = "HTTPCode_ELB_4XX_Count", "color" = "#ffbb78" }
  ]
}
