module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Capacity"

  defaults = {
    MetricNamespace = "AWS/ElastiCache"
    CacheClusterId  = var.redis_name
  }

  period = var.period

  metrics = [
    { MetricName = "DatabaseCapacityUsagePercentage", color = "#EF8BBE", anomaly_detection = var.anomaly_detection, anomaly_deviation = var.anomaly_deviation },
  ]
}
