data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Network"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period

  metrics = [
    { MetricName = "NetworkReceiveThroughput", anomaly_detection = var.anomaly_detection },
    { MetricName = "NetworkTransmitThroughput", anomaly_detection = var.anomaly_detection },
  ]
}