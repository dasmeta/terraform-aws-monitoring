module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Errors"

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
    { MetricName = "5xxErrorRate", color = "#FF0F3C" }
  ]
}
