module "monitoring_dashboard" {
  source = "./modules/dashboard/"

  count = length(var.application_monitroing_dashboard) > 0 ? 1 : 0

  name = var.name
  rows = var.application_monitroing_dashboard
}
