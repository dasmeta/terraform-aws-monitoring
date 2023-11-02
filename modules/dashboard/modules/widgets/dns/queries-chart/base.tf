data "aws_caller_identity" "project" {
  provider = aws
}

module "base" {
  source = "../../base"

  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name = "Queries"

  region = "us-east-1"

  defaults = {
    MetricNamespace = "AWS/Route53"
    HostedZoneId    = local.zone_id
  }

  stat   = "Sum"
  period = var.period

  metrics = [
    { MetricName = "DNSQueries", color = "#007CEF", anomaly_detection = var.anomaly_detection },
  ]
}
