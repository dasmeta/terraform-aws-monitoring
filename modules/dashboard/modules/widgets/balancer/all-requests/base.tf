module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "All Requests"

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
    { MetricName = "HTTPCode_Target_2XX_Count", color = "#3ECE76" },
    { MetricName = "HTTPCode_Target_3XX_Count", color = "#FFC300" },
    { MetricName = "HTTPCode_Target_4XX_Count", color = "#FF774D" },
    { MetricName = "HTTPCode_Target_5XX_Count", color = "#FF0F3C" },
  ]
}
