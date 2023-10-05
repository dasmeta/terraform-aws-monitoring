module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Replicas / ${var.container}"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
  }

  period = var.period

  metrics = [
    { MetricName = "kube_deployment_spec_replicas", label = "Deployment Spec" },
    { MetricName = "kube_deployment_status_replicas_available", label = "Available" }
  ]
}
