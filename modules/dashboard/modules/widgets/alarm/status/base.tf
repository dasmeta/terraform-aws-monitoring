module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = var.title
  type = "alarm"

  period = var.period

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    stacked           = var.stacked
    type              = "chart"
  }

  alarms = var.alarm_arns
}
