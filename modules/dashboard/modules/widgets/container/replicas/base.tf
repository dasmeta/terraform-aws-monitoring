module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Replicas / ${var.container}"

  defaults = {
    "ClusterName" : var.cluster,
    "Namespace" : var.namespace
    "PodName" : var.container
  }

  period = var.period

  metrics = [
    { "ContainerInsights" : "kube_deployment_spec_replicas", "Style" : { "label" : "Deployment Spec" } },
    { "ContainerInsights" : "kube_deployment_status_replicas_available", "Style" : { "label" : "Available" } }
  ]
}
