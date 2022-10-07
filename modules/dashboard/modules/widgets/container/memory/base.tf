module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Memory / ${var.container}"

  defaults = {
    "ClusterName" : var.cluster,
    "Namespace" : var.namespace
    "PodName" : var.container
  }

  period = var.period

  metrics = [
    { "ContainerInsights" : "pod_memory_utilization", },
    { "ContainerInsights" : "pod_memory_reserved_capacity", "Style" : { "color" : "#d62728" } }
  ]
}
