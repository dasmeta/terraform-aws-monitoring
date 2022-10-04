module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container CPU / ${var.container}"

  metrics = [
    ["ContainerInsights", "pod_cpu_utilization", "PodName", var.container,
    "ClusterName", var.cluster, "Namespace", var.namespace],
    ["ContainerInsights", "pod_cpu_reserved_capacity", "PodName", var.container,
    "ClusterName", var.cluster, "Namespace", var.namespace, { "color" : "#d62728" }]
  ]
}
