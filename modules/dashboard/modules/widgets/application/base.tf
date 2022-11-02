module "base" {
  source = "../base"

  coordinates = var.coordinates

  name = var.title

  period = var.period
  stat   = var.stat

  defaults = {
    MetricNamespace   = "ContainerInsights/Prometheus"
    ClusterName       = var.cluster
    Namespace         = var.namespace
    container_name    = var.container
    app               = var.container
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  metrics = concat(
    [for metric_name in var.metrics : {
      MetricName = metric_name
    }],
    [for metric in var.custom_dimension_metrics : metric]
  )
}
