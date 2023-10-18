module "base" {
  source = "../../base"

  # data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Response Time"

  defaults = {
    MetricNamespace = "AWS/ApplicationELB"
    LoadBalancer    = local.balancer
    TargetGroup     = local.target_group
  }

  period = var.period

  metrics = [
    { MetricName = "TargetResponseTime", anomaly_detection = var.anomaly_detection }
  ]
}
