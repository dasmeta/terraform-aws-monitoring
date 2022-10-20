module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "5XX (${var.balancer})"

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
    { MetricName = "HTTPCode_Target_5XX_Count", "color" = "#d62728" },
    { MetricName = "HTTPCode_ELB_5XX_Count", "color" = "#ff9896" },
  ]
}
