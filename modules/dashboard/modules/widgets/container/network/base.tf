module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Network / ${var.container}"

  defaults = {
    "ClusterName" : var.cluster,
    "Namespace" : var.namespace
    "PodName" : var.container
  }

  period = var.period

  metrics = [
    { "ContainerInsights" : "pod_network_rx_bytes", "Style" : { "color" : "#17becf" } },
    { "ContainerInsights" : "pod_network_tx_bytes", "Style" : { "color" : "#e377c2" } }
  ]
}
