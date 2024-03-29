module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "FreeableMemory / ${var.rds_name}"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period

  metrics = [
    { MetricName = "FreeableMemory" },
  ]
}
