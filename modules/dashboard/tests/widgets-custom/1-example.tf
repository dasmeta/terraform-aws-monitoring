module "dashboard-with-custom-metrics" {
  source = "../../"
  name   = "dashboard-with-custom-metrics"
  rows = [
    [
      {
        type              = "custom",
        title             = "all etc ContainerInsights",
        anomaly_detection = true
        metrics : [
          {
            MetricNamespace = "ContainerInsights"
            MetricName      = "node_memory_utilization"
            ClusterName     = "sandbox"
            visible         = false
            # anomaly_detection = true
          },
          {
            MetricNamespace = "ContainerInsights"
            MetricName      = "pod_network_rx_bytes"
            ClusterName     = "sandbox"
            Service         = "ingress-controller-traefik"
          },
        ]
        expressions : [
          {
            expression = "m1 + m2"
            label      = "m1 + m2"
            visible    = false
          },
          {
            expression = "m1 - m2"
          },
        ]
      }
    ]
  ]
}
