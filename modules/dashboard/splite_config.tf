module "splite_config" {
  for_each = { for item in var.dashboards : item.name => item }
  source   = "./modules/splite_config"
  rows     = each.value.rows
}


