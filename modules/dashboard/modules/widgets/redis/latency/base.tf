module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Latency"

  stat = "Average"

  defaults = {
    MetricNamespace = "AWS/ElastiCache"
    CacheClusterId  = var.redis_name
  }

  period = var.period

  metrics = [
    { MetricName = "KeyBasedCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "NonKeyTypeCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "StringBasedCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "ListBasedCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "SortedSetBasedCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "GetTypeCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "EvalBasedCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
    { MetricName = "SetTypeCmdsLatency", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
  ]
}
