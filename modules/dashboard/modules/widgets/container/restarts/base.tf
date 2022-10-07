module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Container Restarts / ${var.container}"

  defaults = {
    "ClusterName" : var.cluster,
    "Namespace" : var.namespace
    "PodName" : var.container
  }

  period = var.period

  metrics = [
    { "ContainerInsights" : "pod_number_of_container_restarts", "Style" : { "color" : "#d62728" } }
  ]
}
