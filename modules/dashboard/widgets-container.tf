# Container widgets
module "container_cpu_widget" {
  source = "./modules/widgets/container/cpu"

  count = length(local.container_cpu)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_cpu[count.index].coordinates

  # stats
  period = local.container_cpu[count.index].period

  # container
  container = local.container_cpu[count.index].container
  cluster   = local.container_cpu[count.index].cluster
  namespace = local.container_cpu[count.index].namespace

  account_id        = try(local.container_cpu[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_cpu[count.index].anomaly_detection, false)
}

module "container_memory_widget" {
  source = "./modules/widgets/container/memory"

  count = length(local.container_memory)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_memory[count.index].coordinates

  # stats
  period = local.container_memory[count.index].period

  # container
  container = local.container_memory[count.index].container
  cluster   = local.container_memory[count.index].cluster
  namespace = local.container_memory[count.index].namespace

  account_id        = try(local.container_memory[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_memory[count.index].anomaly_detection, false)
}

module "container_network_widget" {
  source = "./modules/widgets/container/network"

  count = length(local.container_network)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_network[count.index].coordinates

  # stats
  period = local.container_network[count.index].period

  # container
  container = local.container_network[count.index].container
  cluster   = local.container_network[count.index].cluster
  namespace = local.container_network[count.index].namespace

  account_id        = try(local.container_network[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_network[count.index].anomaly_detection, false)

}

module "container_restarts_widget" {
  source = "./modules/widgets/container/restarts"

  count = length(local.container_restarts)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_restarts[count.index].coordinates

  # stats
  period = local.container_restarts[count.index].period

  # container
  container = local.container_restarts[count.index].container
  cluster   = local.container_restarts[count.index].cluster
  namespace = local.container_restarts[count.index].namespace

  account_id        = try(local.container_restarts[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_restarts[count.index].anomaly_detection, false)
}
