module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Memory"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }

  period = var.period

  metrics = [
    { MetricName = "pod_memory_limit", color = "#FF0F3C", label = "Limit" },
    { MetricName = "pod_memory_working_set", color = "#007CEF", label = "Current", anomaly_detection = var.anomaly_detection }
  ]
}
