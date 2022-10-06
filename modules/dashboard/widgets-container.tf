# Container widgets
module "container_cpu_widget" {
  source = "./modules/widgets/container/cpu"

  count = length(local.container_cpu)

  # coordinates
  coordinates = local.container_cpu[count.index].coordinates

  # stats
  period = local.container_cpu[count.index].period

  # container
  container = local.container_cpu[count.index].container
  cluster   = local.container_cpu[count.index].cluster
  namespace = local.container_cpu[count.index].namespace
}

module "container_memory_widget" {
  source = "./modules/widgets/container/memory"

  count = length(local.container_memory)

  # coordinates
  coordinates = local.container_memory[count.index].coordinates

  # stats
  period = local.container_memory[count.index].period

  # container
  container = local.container_memory[count.index].container
  cluster   = local.container_memory[count.index].cluster
  namespace = local.container_memory[count.index].namespace
}

module "container_network_widget" {
  source = "./modules/widgets/container/network"

  count = length(local.container_network)

  # coordinates
  coordinates = local.container_network[count.index].coordinates

  # stats
  period = local.container_network[count.index].period

  # container
  container = local.container_network[count.index].container
  cluster   = local.container_network[count.index].cluster
  namespace = local.container_network[count.index].namespace
}

module "container_restarts_widget" {
  source = "./modules/widgets/container/restarts"

  count = length(local.container_restarts)

  # coordinates
  coordinates = local.container_restarts[count.index].coordinates

  # stats
  period = local.container_restarts[count.index].period

  # container
  container = local.container_restarts[count.index].container
  cluster   = local.container_restarts[count.index].cluster
  namespace = local.container_restarts[count.index].namespace
}
