module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Swap Usage"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  annotations = {
    horizontal = [
      {
        color : "#fe6e73",
        label : "Too Much Swap Usage",
        value : 50000000,
      }
    ]
  }
  period = var.period

  metrics = [
    { MetricName = "SwapUsage", color = "#FE6E73" },
  ]
}
