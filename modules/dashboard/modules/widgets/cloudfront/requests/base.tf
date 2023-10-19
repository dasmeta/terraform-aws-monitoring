module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Requests"

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
    { MetricName = "Requests", "color" = "#2ca02c" }
  ]
}
