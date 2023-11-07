module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Restarts"

  stat = "Maximum"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }

  period = var.period

  metrics = [
    { MetricName = "pod_number_of_container_restarts", label = "Restarts", color = "#d62728", anomaly_detection = var.anomaly_detection }
  ]
}
