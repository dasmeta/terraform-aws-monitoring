module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Network < In"

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
    { MetricName = "pod_network_rx_bytes", color = "#17becf", label = "In Avg", stat = "Average", anomaly_detection = var.anomaly_detection },
    { MetricName = "pod_network_rx_bytes", color = "#007CEF", label = "In Max", stat = "Maximum", anomaly_detection = var.anomaly_detection },
  ]
}
