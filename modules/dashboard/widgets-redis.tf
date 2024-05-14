# Container widgets
module "widget_redis_cache_hit" {
  source = "./modules/widgets/redis/cache-hit"

  count = length(local.redis_cache_hit)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_cache_hit[count.index].coordinates

  # stats
  period = local.redis_cache_hit[count.index].period

  # redis name
  redis_name        = local.redis_cache_hit[count.index].redis_name
  anomaly_detection = try(local.redis_cache_hit[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.redis_cache_hit[count.index].anomaly_deviation, 6)
}

module "widget_redis_capacity" {
  source = "./modules/widgets/redis/capacity"

  count = length(local.redis_capacity)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_capacity[count.index].coordinates

  # stats
  period = local.redis_capacity[count.index].period

  # redis name
  redis_name = local.redis_capacity[count.index].redis_name
}

module "widget_redis_cpu" {
  source = "./modules/widgets/redis/cpu"

  count = length(local.redis_cpu)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_cpu[count.index].coordinates

  # stats
  period = local.redis_cpu[count.index].period

  # redis name
  redis_name = local.redis_cpu[count.index].redis_name
}

module "widget_redis_current_connections" {
  source = "./modules/widgets/redis/current-connections"

  count = length(local.redis_current_connections)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_current_connections[count.index].coordinates

  # stats
  period = local.redis_current_connections[count.index].period

  # redis name
  redis_name = local.redis_current_connections[count.index].redis_name
}

module "widget_redis_latency" {
  source = "./modules/widgets/redis/latency"

  count = length(local.redis_latency)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_latency[count.index].coordinates

  # stats
  period = local.redis_latency[count.index].period

  # redis name
  redis_name = local.redis_latency[count.index].redis_name
}

module "widget_redis_memory" {
  source = "./modules/widgets/redis/memory"

  count = length(local.redis_memory)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_memory[count.index].coordinates

  # stats
  period = local.redis_memory[count.index].period

  # redis name
  redis_name = local.redis_memory[count.index].redis_name
}

module "widget_redis_network" {
  source = "./modules/widgets/redis/network"

  count = length(local.redis_network)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_network[count.index].coordinates

  # stats
  period = local.redis_network[count.index].period

  # redis name
  redis_name = local.redis_network[count.index].redis_name
}

module "widget_redis_new_connections" {
  source = "./modules/widgets/redis/new-connections"

  count = length(local.redis_new_connections)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.redis_new_connections[count.index].coordinates

  # stats
  period = local.redis_new_connections[count.index].period

  # redis name
  redis_name = local.redis_new_connections[count.index].redis_name
}
