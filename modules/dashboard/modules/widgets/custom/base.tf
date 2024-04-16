module "base" {
  source = "../base"

  coordinates = var.coordinates

  name = var.title

  period = var.period
  stat   = var.stat
  yAxis  = var.yAxis

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  metrics     = var.metrics
  expressions = var.expressions
}
