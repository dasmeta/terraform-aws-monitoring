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

  # container
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

  # container
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

  # container
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

  # container
  rds_name = local.rds_connections[count.index].rds_name
}
