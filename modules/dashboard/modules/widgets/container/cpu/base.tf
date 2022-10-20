module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container CPU / ${var.container}"

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
    { MetricName = "pod_cpu_utilization" },
    { MetricName = "pod_cpu_reserved_capacity", color = "#d62728" }
  ]
}
