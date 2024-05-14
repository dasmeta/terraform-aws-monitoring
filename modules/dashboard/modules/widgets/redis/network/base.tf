module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Network"

  defaults = {
    MetricNamespace = "AWS/ElastiCache"
    CacheClusterId  = var.redis_name
  }

  period = var.period

  metrics = [
    { MetricName = "NetworkMaxBytesIn", color = "#17becf", label = "In", stat = "Average", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "NetworkMaxBytesOut", color = "#e377c2", label = "Out", stat = "Average", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
  ]
}
