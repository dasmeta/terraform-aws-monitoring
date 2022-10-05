module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Memory / ${var.container}"

  metrics = [
    { "ContainerInsights" : "pod_network_rx_bytes", "Style" : { "color" : "#17becf" } },
    { "ContainerInsights" : "pod_network_tx_bytes", "Style" : { "color" : "#e377c2" } }
  ]
}
