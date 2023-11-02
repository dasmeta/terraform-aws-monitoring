module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = "External Health Check"

  defaults = {
    MetricNamespace = "AWS/Route53"
    HealthCheckId   = var.healthcheck_id
  }

  period = var.period
  region = "us-east-1"

  metrics = [
    { MetricName = "HealthCheckPercentageHealthy", anomaly_detection = var.anomaly_detection },
    { MetricName = "HealthCheckStatus", anomaly_detection = var.anomaly_detection }
  ]
}
