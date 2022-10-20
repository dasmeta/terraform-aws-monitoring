module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Memory / ${var.container}"

  defaults = {
    MetricNamespace   = "ContainerInsights"
    ClusterName       = var.cluster
    Namespace         = var.namespace
    PodName           = var.container
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  period = var.period

  metrics = [
    { MetricName = "pod_memory_utilization", },
    { MetricName = "pod_memory_reserved_capacity", color : "#d62728" }
  ]
}
