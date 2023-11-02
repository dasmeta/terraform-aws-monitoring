module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "Error Rate"

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
    { MetricName = "TotalErrorRate", color = "#FF103B" }
  ]
}
