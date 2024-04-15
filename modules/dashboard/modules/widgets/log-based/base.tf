module "base" {
  source = "../base"

  coordinates = var.coordinates

  name = var.title

  period = var.period

  defaults = {
    MetricNamespace   = "LogBasedMetrics${var.account_id == null ? "" : "/${var.account_id}"}"
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  metrics = var.metrics
}
