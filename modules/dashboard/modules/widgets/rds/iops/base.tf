module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "IOPS"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period

  metrics = [
    { MetricName = "ReadIOPS", color = "#7AAFF9", anomaly_detection = var.anomaly_detection },
    { MetricName = "WriteIOPS", color = "#EF8BBE", anomaly_detection = var.anomaly_detection },
  ]
}
