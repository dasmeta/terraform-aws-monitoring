module "container_cpu_widget" {
  source = "./widget/container/cpu"

  for_each = { for item in var.dashboards : item.name => item }
  cpu      = module.splite_config[each.key].cpu
  default  = each.value.defaults
}

module "container_memory_widget" {
  source = "./widget/container/memory"

  for_each = { for item in var.dashboards : item.name => item }
  memory   = module.splite_config[each.key].memory
  default  = each.value.defaults
}

module "container_network_widget" {
  source = "./widget/container/network"

  for_each = { for item in var.dashboards : item.name => item }
  network  = module.splite_config[each.key].network
  default  = each.value.defaults
}

module "container_restarts_widget" {
  source = "./widget/container/restart"

  for_each = { for item in var.dashboards : item.name => item }
  restart  = module.splite_config[each.key].restarts
  default  = each.value.defaults
}

module "container_traffic_widget" {
  source = "./widget/container/traffic"

  for_each = { for item in var.dashboards : item.name => item }
  traffic  = module.splite_config[each.key].traffic
  default  = each.value.defaults
}

module "text" {
  source = "./widget/text"

  for_each = { for item in var.dashboards : item.name => item }
  text     = module.splite_config[each.key].text
  default  = each.value.defaults
}
