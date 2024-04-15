module "base" {
  source          = "../../base"
  platform        = var.platform
  data_source_uid = var.data_source_uid

  coordinates = var.coordinates

  name    = var.title
  type    = "log"
  view    = var.view
  stacked = var.stacked

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
    anomaly_deviation = var.anomaly_deviation
  }

  query   = "${var.query} | STATS ${join(",", var.stats)} BY bin(${var.time_period})"
  sources = var.sources
}
