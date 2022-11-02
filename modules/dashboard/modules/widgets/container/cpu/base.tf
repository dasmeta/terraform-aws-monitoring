data "aws_caller_identity" "project" {
  provider = aws
}

locals {
  account_id = var.account_id == null ? "${data.aws_caller_identity.project.account_id}" : var.account_id
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Container CPU / ${var.container}"

  defaults = {
    MetricNamespace   = "ContainerInsights"
    ClusterName       = var.cluster
    Namespace         = var.namespace
    PodName           = var.container
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  period = var.period

  metrics = [
    { MetricName = "pod_cpu_utilization_over_pod_limit" },
    { MetricName = "pod_cpu_utilization" },
    { MetricName = "pod_cpu_reserved_capacity", color = "#d62728" }
  ]
}
