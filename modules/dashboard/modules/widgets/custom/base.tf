module "base" {
  source = "../base"

  coordinates = var.coordinates

  name = var.title

  period = var.period
  stat   = var.stat

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  metrics = var.metrics
}
