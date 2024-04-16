module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Request Count"

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    TargetGroup     = local.target_group
  }

  period = var.period

  metrics = [
    { MetricName = "RequestCountPerTarget", color = "#007CEF", label = "RequestCountPerTarget Avg", stat = "Average", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "RequestCountPerTarget", color = "#7FFFD4", label = "RequestCountPerTarget Max", stat = "Maximum", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation }
  ]
}
