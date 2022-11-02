module "base" {
  source = "../../base"

  coordinates = var.coordinates

  name = var.title
  type = "log"
  view = "table"

  defaults = {
    accountId         = var.account_id
    anomaly_detection = var.anomaly_detection
  }

  query   = var.query
  sources = var.sources
}
