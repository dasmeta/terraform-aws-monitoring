module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Memory / ${var.container}"

  metrics = [
    ["ContainerInsights", "pod_memory_utilization", "PodName", var.container,
    "ClusterName", var.cluster, "Namespace", var.namespace],
    ["ContainerInsights", "pod_memory_reserved_capacity", "PodName", var.container,
    "ClusterName", var.cluster, "Namespace", var.namespace, { "color" : "#d62728" }]
  ]
}
