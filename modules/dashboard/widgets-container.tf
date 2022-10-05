# // Container
module "container_cpu_widget" {
  source = "./modules/widgets/container/cpu"

  count = length(local.widget_config["container/cpu"])

  # container
  container = local.widget_config["container/cpu"][count.index].container
  cluster   = local.widget_config["container/cpu"][count.index].cluster
  namespace = local.widget_config["container/cpu"][count.index].namespace

  # stats
  period = local.widget_config["container/cpu"][count.index].period

  # coordinates
  coordinates = local.widget_config["container/cpu"][count.index].coordinates
}

module "container_memory_widget" {
  source = "./modules/widgets/container/memory"

  count = length(local.widget_config["container/cpu"])

  # container
  container = local.widget_config["container/cpu"][count.index].container
  cluster   = local.widget_config["container/cpu"][count.index].cluster
  namespace = local.widget_config["container/cpu"][count.index].namespace

  # stats
  period = local.widget_config["container/cpu"][count.index].period

  # coordinates
  coordinates = local.widget_config["container/cpu"][count.index].coordinates
}

# module "container_network_widget" {
#   source = "./modules/widgets/container/network"

#   network = local.widget_config["container/network"]
#   # default = var.defaults
# }

# module "container_restarts_widget" {
#   source = "./modules/widgets/container/restart"

#   restart = local.widget_config["container/restarts"]
#   # default = var.defaults
# }
