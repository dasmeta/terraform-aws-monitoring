module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Restarts / ${var.container}"

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
    { MetricName = "pod_number_of_container_restarts", color = "#d62728" }
  ]
}
