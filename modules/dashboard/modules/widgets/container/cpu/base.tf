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

  name = "CPU"

  defaults = {
    MetricNamespace = "ContainerInsights"
    ClusterName     = var.cluster
    Namespace       = var.namespace
    PodName         = var.container
    accountId       = var.account_id
  }

  period = var.period

  metrics = [
    { MetricName = "pod_cpu_limit", color = "#FF0F3C", label = "Limit" },
    { MetricName = "pod_cpu_usage_total", color = "#D400BF", label = "Current Avg", stat = "Average", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "pod_cpu_usage_total", color = "#007CEF", label = "Current Max", stat = "Maximum", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation }
  ]
}
