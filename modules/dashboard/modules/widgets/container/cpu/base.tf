module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container CPU / ${var.container}"

  defaults = {
    "ClusterName" : var.cluster,
    "Namespace" : var.namespace
    "PodName" : var.container
  }


  metrics = [
    { "ContainerInsights" : "pod_cpu_utilization", },
    { "ContainerInsights" : "pod_cpu_reserved_capacity", "Style" : { "color" : "#d62728" } }
  ]
}
