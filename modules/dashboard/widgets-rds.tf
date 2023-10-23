# Container widgets
module "widget_rds_cpu" {
  source = "./modules/widgets/rds/cpu"

  count = length(local.rds_cpu)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_cpu[count.index].coordinates

  # stats
  period = local.rds_cpu[count.index].period

  # rds name
  rds_name = local.rds_cpu[count.index].rds_name
}

module "widget_rds_memory" {
  source = "./modules/widgets/rds/memory"

  count = length(local.rds_memory)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_memory[count.index].coordinates

  # stats
  period = local.rds_memory[count.index].period

  # rds name
  rds_name = local.rds_memory[count.index].rds_name
}

module "widget_rds_disk" {
  source = "./modules/widgets/rds/disk"

  count = length(local.rds_disk)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_disk[count.index].coordinates

  # stats
  period = local.rds_disk[count.index].period

  # rds name
  rds_name = local.rds_disk[count.index].rds_name
}

module "widget_rds_db_connections" {
  source = "./modules/widgets/rds/db-connections"

  count = length(local.rds_connections)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_connections[count.index].coordinates

  # stats
  period = local.rds_connections[count.index].period

  # rds name
  rds_name                 = local.rds_connections[count.index].rds_name
  db_max_connections_count = try(local.rds_connections[count.index].db_max_connections_count, null)
}

module "widget_rds_network" {
  source = "./modules/widgets/rds/network"

  count = length(local.rds_network)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_network[count.index].coordinates

  # stats
  period = local.rds_network[count.index].period

  # rds name
  rds_name = local.rds_network[count.index].rds_name
}

module "widget_rds_iops" {
  source = "./modules/widgets/rds/iops"

  count = length(local.rds_iops)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_iops[count.index].coordinates

  # stats
  period = local.rds_iops[count.index].period

  # rds name
  rds_name = local.rds_iops[count.index].rds_name
}

module "widget_rds_performance" {
  source = "./modules/widgets/rds/performance"

  count = length(local.rds_performance)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_performance[count.index].coordinates

  # stats
  period = local.rds_performance[count.index].period

  # rds name
  rds_name = local.rds_performance[count.index].rds_name
}

module "widget_rds_free_storage" {
  source = "./modules/widgets/rds/free-storage"

  count = length(local.rds_free_storage)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_free_storage[count.index].coordinates

  # stats
  period = local.rds_free_storage[count.index].period

  # rds name
  rds_name = local.rds_free_storage[count.index].rds_name
}

module "widget_rds_swap" {
  source = "./modules/widgets/rds/swap"

  count = length(local.rds_swap)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_swap[count.index].coordinates

  # stats
  period = local.rds_swap[count.index].period

  # rds name
  rds_name = local.rds_swap[count.index].rds_name
}

module "widget_rds_disk_latency" {
  source = "./modules/widgets/rds/disk-latency"

  count = length(local.rds_disk_latency)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.rds_disk_latency[count.index].coordinates

  # stats
  period = local.rds_disk_latency[count.index].period

  # rds name
  rds_name = local.rds_disk_latency[count.index].rds_name
}
