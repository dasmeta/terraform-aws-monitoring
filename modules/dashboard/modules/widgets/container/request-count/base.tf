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
    { MetricName = "RequestCountPerTarget", color = "#007CEF", anomaly_detection = var.anomaly_detection }
  ]
}
