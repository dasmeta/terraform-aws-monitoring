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

  count = length(local.widget_config["container/memory"])

  # container
  container = local.widget_config["container/memory"][count.index].container
  cluster   = local.widget_config["container/memory"][count.index].cluster
  namespace = local.widget_config["container/memory"][count.index].namespace

  # stats
  period = local.widget_config["container/memory"][count.index].period

  # coordinates
  coordinates = local.widget_config["container/memory"][count.index].coordinates
}

module "container_network_widget" {
  source = "./modules/widgets/container/network"

  count = length(local.widget_config["container/network"])

  # container
  container = local.widget_config["container/network"][count.index].container
  cluster   = local.widget_config["container/network"][count.index].cluster
  namespace = local.widget_config["container/network"][count.index].namespace

  # stats
  period = local.widget_config["container/network"][count.index].period

  # coordinates
  coordinates = local.widget_config["container/network"][count.index].coordinates
}

module "container_restarts_widget" {
  source = "./modules/widgets/container/restarts"

  count = length(local.widget_config["container/restarts"])

  # container
  container = local.widget_config["container/restarts"][count.index].container
  cluster   = local.widget_config["container/restarts"][count.index].cluster
  namespace = local.widget_config["container/restarts"][count.index].namespace

  # stats
  period = local.widget_config["container/restarts"][count.index].period

  # coordinates
  coordinates = local.widget_config["container/restarts"][count.index].coordinates
}
