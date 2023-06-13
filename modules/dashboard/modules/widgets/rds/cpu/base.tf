data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "CPUUtilization / ${var.rds_name}"

  defaults = {
    MetricNamespace      = "AWS/RDS"
    DBInstanceIdentifier = var.rds_name
  }

  period = var.period
  # region = "eu-central-1"
  metrics = [
    { MetricName = "CPUUtilization" },
  ]
}
