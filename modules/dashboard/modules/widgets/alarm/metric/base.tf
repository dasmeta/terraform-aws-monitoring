module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name            = var.title == null ? split(":alarm:", var.alarm_arn)[1] : var.title
  stacked         = var.stacked
  type            = "metric"
  stat            = null
  period          = null
  metrics         = null
  properties_type = "chart"

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
    stacked           = var.stacked
    view              = var.view
  }

  annotations = {
    alarms = [var.alarm_arn]
  }
}
