module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "DiskUsedPercent / ${var.rds_name}"

  defaults = {
    MetricNamespace      = "RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period

  metrics = [
    { MetricName = "diskUsedPercent" },
  ]
}
