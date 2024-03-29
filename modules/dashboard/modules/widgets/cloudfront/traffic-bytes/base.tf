module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Traffic Bytes"

  # stats
  stat   = "Average"
  period = var.period
  region = "us-east-1"

  defaults = {
    MetricNamespace = "AWS/CloudFront"
    Region          = "Global"
    DistributionId  = var.distribution
  }

  metrics = [
    { MetricName = "BytesUploaded", color = "#EF8BBE" },
    { MetricName = "BytesDownloaded", color = "#7AAFF9" },
  ]
}
