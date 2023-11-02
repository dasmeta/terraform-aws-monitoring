module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Replicas"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
  }

  period = var.period

  metrics = [
    { MetricName = "kube_deployment_spec_replicas", PodName = var.container, label = "Deployment Spec", anomaly_detection = var.anomaly_detection },
    { MetricName = "kube_deployment_status_replicas_available", PodName = var.container, label = "Available", anomaly_detection = var.anomaly_detection },
    { MetricNamespace = "ContainerInsights", Service = var.container, MetricName = "service_number_of_running_pods", label = "Available", anomaly_detection = var.anomaly_detection }
  ]
}
