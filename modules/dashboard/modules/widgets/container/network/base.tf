module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Network / ${var.container}"

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
    { MetricName = "pod_network_rx_bytes", color = "#17becf" },
    { MetricName = "pod_network_tx_bytes", color = "#e377c2" }
  ]
}
