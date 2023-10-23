data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Connections"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  annotations = var.db_max_connections_count != null ? {
    horizontal = [
      {
        label : "Max"
        value : var.db_max_connections_count
      }
    ]
  } : {}
  period = var.period

  metrics = [
    { MetricName = "DatabaseConnections", color = "#007CEF", label = "Connections", anomaly_detection = var.anomaly_detection },
  ]
}
