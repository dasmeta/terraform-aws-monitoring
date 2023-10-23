data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Disk Latency"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  annotations = {
    horizontal = [
      {
        color : "#fe6e73",
        label : "Above 100ms",
        value : 0.1,
      }
    ]
  }
  period = var.period

  metrics = [
    { MetricName = "WriteLatency", color = "#EF8BBE" },
    { MetricName = "ReadLatency", color = "#7AAFF9" }
  ]
}
