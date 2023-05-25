module "monitoring_dashboard" {
  source  = "dasmeta/monitoring/aws//modules/dashboard"
  version = "1.5.1"

  count = length(var.application_monitroing_dashboard) > 0 ? 1 : 0

  name = var.name
  rows = var.application_monitroing_dashboard
}
