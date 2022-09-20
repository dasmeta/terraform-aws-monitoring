// Container
module "container_cpu_widget" {
  source = "./modules/widget/container/cpu"

  for_each = { for item in var.dashboards : item.name => item }
  cpu      = module.splite_config[each.key].cpu
  default  = each.value.defaults
}

module "container_memory_widget" {
  source = "./modules/widget/container/memory"

  for_each = { for item in var.dashboards : item.name => item }
  memory   = module.splite_config[each.key].memory
  default  = each.value.defaults
}

module "container_network_widget" {
  source = "./modules/widget/container/network"

  for_each = { for item in var.dashboards : item.name => item }
  network  = module.splite_config[each.key].network
  default  = each.value.defaults
}

module "container_restarts_widget" {
  source = "./modules/widget/container/restart"

  for_each = { for item in var.dashboards : item.name => item }
  restart  = module.splite_config[each.key].restarts
  default  = each.value.defaults
}


// Traffic
module "container_traffic_5xx_widget" {
  source = "./modules/widget/traffic/5xx"

  for_each    = { for item in var.dashboards : item.name => item }
  traffic_5xx = module.splite_config[each.key].traffic_5xx
  default     = each.value.defaults
}

module "container_traffic_4xx_widget" {
  source = "./modules/widget/traffic/4xx"

  for_each    = { for item in var.dashboards : item.name => item }
  traffic_4xx = module.splite_config[each.key].traffic_4xx
  default     = each.value.defaults
}

module "container_traffic_2xx_widget" {
  source = "./modules/widget/traffic/2xx"

  for_each    = { for item in var.dashboards : item.name => item }
  traffic_2xx = module.splite_config[each.key].traffic_2xx
  default     = each.value.defaults
}


// Text
module "text" {
  source = "./modules/widget/text"

  for_each = { for item in var.dashboards : item.name => item }
  text     = module.splite_config[each.key].text
  default  = each.value.defaults
}
