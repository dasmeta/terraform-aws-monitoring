//Tese metrics are exposed when Performance Insights is enabled for the DB
module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Performance Metric - Load"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period

  metrics = [
    { MetricName = "DBLoad", anomaly_detection = var.anomaly_detection },
    { MetricName = "DBLoadNonCPU" },
    { MetricName = "DBLoadCPU" },
  ]
}
