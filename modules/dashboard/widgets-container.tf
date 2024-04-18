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
  anomaly_detection = try(local.container_cpu[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_cpu[count.index].anomaly_deviation, 6)
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
  anomaly_detection = try(local.container_memory[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_memory[count.index].anomaly_deviation, 6)
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
  anomaly_detection = try(local.container_network[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_network[count.index].anomaly_deviation, 6)
}

module "container_network_in_widget" {
  source = "./modules/widgets/container/network-in"

  count = length(local.container_network_in)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_network_in[count.index].coordinates

  # stats
  period = local.container_network_in[count.index].period

  # container
  container = local.container_network_in[count.index].container
  cluster   = local.container_network_in[count.index].cluster
  namespace = local.container_network_in[count.index].namespace

  account_id        = try(local.container_network_in[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_network_in[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_network_in[count.index].anomaly_deviation, 6)
}

module "container_network_out_widget" {
  source = "./modules/widgets/container/network-out"

  count = length(local.container_network_out)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric

  # coordinates
  coordinates = local.container_network_out[count.index].coordinates

  # stats
  period = local.container_network_out[count.index].period

  # container
  container = local.container_network_out[count.index].container
  cluster   = local.container_network_out[count.index].cluster
  namespace = local.container_network_out[count.index].namespace

  account_id        = try(local.container_network_out[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.container_network_out[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_network_out[count.index].anomaly_deviation, 6)
}

module "container_replicas_widget" {
  source = "./modules/widgets/container/replicas"

  count = length(local.container_replicas)

  # coordinates
  coordinates = local.container_replicas[count.index].coordinates

  # stats
  period = local.container_replicas[count.index].period

  # container
  container = local.container_replicas[count.index].container
  cluster   = local.container_replicas[count.index].cluster
  namespace = local.container_replicas[count.index].namespace

  anomaly_detection = try(local.container_replicas[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_replicas[count.index].anomaly_deviation, 6)
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
  anomaly_detection = try(local.container_restarts[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_restarts[count.index].anomaly_deviation, 6)
}

module "container_request_count_widget" {
  source = "./modules/widgets/container/request-count"

  count = length(local.container_request_count)

  # coordinates
  coordinates = local.container_request_count[count.index].coordinates

  # stats
  period = local.container_request_count[count.index].period

  target_group_arn  = try(local.container_request_count[count.index].target_group_arn, null)
  anomaly_detection = try(local.container_request_count[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_request_count[count.index].anomaly_deviation, 6)
}

module "container_response_time_widget" {
  source = "./modules/widgets/container/response-time"

  count = length(local.container_response_time)

  # coordinates
  coordinates = local.container_response_time[count.index].coordinates

  # stats
  period = local.container_response_time[count.index].period

  target_group_arn = try(local.container_response_time[count.index].target_group_arn, null)

  # balancer
  balancer_arn  = try(local.container_response_time[count.index].balancer_arn, null)
  balancer_name = try(local.container_response_time[count.index].balancer_name, null)

  anomaly_detection = try(local.container_response_time[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_response_time[count.index].anomaly_deviation, 6)
}

module "container_external_health_check_widget" {
  source = "./modules/widgets/container/external-health-check"

  count = length(local.container_external_health_check)

  # coordinates
  coordinates = local.container_external_health_check[count.index].coordinates

  # stats
  period            = local.container_external_health_check[count.index].period
  healthcheck_id    = local.container_external_health_check[count.index].healthcheck_id
  anomaly_detection = try(local.container_external_health_check[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_external_health_check[count.index].anomaly_deviation, 6)
}

module "container_error_rate" {
  source = "./modules/widgets/container/error-rate"

  count = length(local.container_error_rate)

  # coordinates
  coordinates = local.container_error_rate[count.index].coordinates

  # stats
  period = local.container_error_rate[count.index].period

  target_group_arn = try(local.container_error_rate[count.index].target_group_arn, null)

  # balancer
  balancer_arn  = try(local.container_error_rate[count.index].balancer_arn, null)
  balancer_name = try(local.container_error_rate[count.index].balancer_name, null)

  anomaly_detection = try(local.container_error_rate[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_error_rate[count.index].anomaly_deviation, 6)
}

module "container_all_requests" {
  source = "./modules/widgets/container/all-requests"

  count = length(local.container_all_requests)

  # coordinates
  coordinates = local.container_all_requests[count.index].coordinates

  # stats
  period = local.container_all_requests[count.index].period

  target_group_arn = try(local.container_all_requests[count.index].target_group_arn, null)

  # balancer
  balancer_arn  = try(local.container_all_requests[count.index].balancer_arn, null)
  balancer_name = try(local.container_all_requests[count.index].balancer_name, null)

  anomaly_detection = try(local.container_all_requests[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_all_requests[count.index].anomaly_deviation, 6)
}

module "container_health_check" {
  source = "./modules/widgets/container/health-check"

  count = length(local.container_health_check)

  # coordinates
  coordinates = local.container_health_check[count.index].coordinates

  # stats
  period = local.container_health_check[count.index].period

  target_group_arn = try(local.container_health_check[count.index].target_group_arn, null)

  # balancer
  balancer_arn  = try(local.container_health_check[count.index].balancer_arn, null)
  balancer_name = try(local.container_health_check[count.index].balancer_name, null)

  anomaly_detection = try(local.container_health_check[count.index].anomaly_detection, true)
  anomaly_deviation = try(local.container_health_check[count.index].anomaly_deviation, 6)
}

# Logs insight App version widgets
module "container_release_version" {
  source = "./modules/widgets/container/release-version"

  count = length(local.container_release_version)

  # coordinates
  coordinates = local.container_release_version[count.index].coordinates

  container      = local.container_release_version[count.index].container
  namespace      = local.container_release_version[count.index].namespace
  version_label  = try(local.container_release_version[count.index].version_label, "app-version")
  log_group_name = local.container_release_version[count.index].log_group_name

  account_id        = try(local.container_release_version[count.index].accountId, null)
  anomaly_detection = try(local.container_release_version[count.index].anomaly_detection, false)
}
