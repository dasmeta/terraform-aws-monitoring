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
    { MetricName = "pod_memory_working_set", color = "#007CEF", label = "Current Avg", stat = "Average", anomaly_detection = var.anomaly_detection },
    { MetricName = "pod_memory_working_set", color = "#D400BF", label = "Current Max", stat = "Maximum", anomaly_detection = var.anomaly_detection }
  ]
}
