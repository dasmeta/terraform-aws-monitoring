// Container
module "container_cpu_widget" {
  source = "./modules/widget/container/cpu"

  cpu     = module.splite_config.cpu
  default = var.defaults
}

module "container_memory_widget" {
  source = "./modules/widget/container/memory"

  memory  = module.splite_config.memory
  default = var.defaults
}

module "container_network_widget" {
  source = "./modules/widget/container/network"

  network = module.splite_config.network
  default = var.defaults
}

module "container_restarts_widget" {
  source = "./modules/widget/container/restart"

  restart = module.splite_config.restarts
  default = var.defaults
}

// Traffic
module "container_traffic_5xx_widget" {
  source = "./modules/widget/traffic/5xx"

  traffic_5xx = module.splite_config.traffic_5xx
  default     = var.defaults
}

module "container_traffic_4xx_widget" {
  source = "./modules/widget/traffic/4xx"

  traffic_4xx = module.splite_config.traffic_4xx
  default     = var.defaults
}

module "container_traffic_2xx_widget" {
  source = "./modules/widget/traffic/2xx"

  traffic_2xx = module.splite_config.traffic_2xx
  default     = var.defaults
}


// Application

module "application_metric" {
  source      = "./modules/widget/application"
  application = module.splite_config.application_metric
  default     = var.defaults
}

// Custom

module "custom_metric" {
  source        = "./modules/widget/custom"
  custom_metric = module.splite_config.custom_metric
  default       = var.defaults
}

// Text
module "text" {
  source = "./modules/widget/text"

  text    = module.splite_config.text
  default = var.defaults
}
