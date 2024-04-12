module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Network / Combined"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }

  period = var.period

  metrics = [
    { MetricName = "pod_network_rx_bytes", color = "#17becf", label = "In Avg", stat = "Average", anomaly_detection = var.anomaly_detection },
    { MetricName = "pod_network_rx_bytes", color = "#007CEF", label = "In Max", stat = "Maximum", anomaly_detection = var.anomaly_detection },
    { MetricName = "pod_network_tx_bytes", color = "#e377c2", label = "Out Avg", stat = "Average", anomaly_detection = var.anomaly_detection },
    { MetricName = "pod_network_tx_bytes", color = "#D400BF", label = "Out Max", stat = "Maximum", anomaly_detection = var.anomaly_detection }
  ]
}
