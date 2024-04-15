# // balancer
module "container_balancer_2xx_widget" {
  source = "./modules/widgets/balancer/2xx"

  count = length(local.balancer_2xx)

  # coordinates
  coordinates = local.balancer_2xx[count.index].coordinates

  # stats
  period = local.balancer_2xx[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_2xx[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_2xx[count.index].balancer_name, null)

  account_id        = try(local.balancer_2xx[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.balancer_2xx[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_2xx[count.index].anomaly_deviation, 6)
}

module "container_balancer_4xx_widget" {
  source = "./modules/widgets/balancer/4xx"

  count = length(local.balancer_4xx)

  # coordinates
  coordinates = local.balancer_4xx[count.index].coordinates

  # stats
  period = local.balancer_4xx[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_4xx[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_4xx[count.index].balancer_name, null)

  account_id = try(local.balancer_4xx[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_4xx[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_4xx[count.index].anomaly_deviation, 6)
}

module "container_balancer_5xx_widget" {
  source = "./modules/widgets/balancer/5xx"

  count = length(local.balancer_5xx)

  # coordinates
  coordinates = local.balancer_5xx[count.index].coordinates

  # stats
  period = local.balancer_5xx[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_5xx[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_5xx[count.index].balancer_name, null)

  account_id = try(local.balancer_5xx[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_5xx[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_5xx[count.index].anomaly_deviation, 6)
}

module "container_balancer_traffic_widget" {
  source = "./modules/widgets/balancer/traffic"

  count = length(local.balancer_traffic)

  # coordinates
  coordinates = local.balancer_traffic[count.index].coordinates

  # stats
  period = local.balancer_traffic[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_traffic[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_traffic[count.index].balancer_name, null)

  account_id = try(local.balancer_traffic[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_traffic[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_traffic[count.index].anomaly_deviation, 6)
}

module "container_balancer_response_time_widget" {
  source = "./modules/widgets/balancer/response-time"

  count = length(local.balancer_response_time)

  # coordinates
  coordinates = local.balancer_response_time[count.index].coordinates

  # stats
  period = local.balancer_response_time[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_response_time[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_response_time[count.index].balancer_name, null)

  account_id = try(local.balancer_response_time[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_response_time[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_response_time[count.index].anomaly_deviation, 6)
}

module "container_balancer_unhealthy_request_count_widget" {
  source = "./modules/widgets/balancer/unhealthy-request-count"

  count = length(local.balancer_unhealthy_request_count)

  # coordinates
  coordinates = local.balancer_unhealthy_request_count[count.index].coordinates

  # stats
  period = local.balancer_unhealthy_request_count[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_unhealthy_request_count[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_unhealthy_request_count[count.index].balancer_name, null)

  account_id = try(local.balancer_unhealthy_request_count[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_unhealthy_request_count[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_unhealthy_request_count[count.index].anomaly_deviation, 6)
}

module "container_balancer_request_count_widget" {
  source = "./modules/widgets/balancer/request-count"

  count = length(local.balancer_request_count)

  # coordinates
  coordinates = local.balancer_request_count[count.index].coordinates

  # stats
  period = local.balancer_request_count[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_request_count[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_request_count[count.index].balancer_name, null)

  account_id = try(local.balancer_request_count[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_request_count[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_request_count[count.index].anomaly_deviation, 6)
}

module "container_balancer_all_requests_widget" {
  source = "./modules/widgets/balancer/all-requests"

  count = length(local.balancer_all_requests)

  # coordinates
  coordinates = local.balancer_all_requests[count.index].coordinates

  # stats
  period = local.balancer_all_requests[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_all_requests[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_all_requests[count.index].balancer_name, null)

  account_id = try(local.balancer_all_requests[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_all_requests[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_all_requests[count.index].anomaly_deviation, 6)
}

module "container_balancer_error_rate" {
  source = "./modules/widgets/balancer/error-rate"

  count = length(local.balancer_error_rate)

  # coordinates
  coordinates = local.balancer_error_rate[count.index].coordinates

  # stats
  period = local.balancer_error_rate[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_error_rate[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_error_rate[count.index].balancer_name, null)

  account_id = try(local.balancer_error_rate[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_error_rate[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_error_rate[count.index].anomaly_deviation, 6)
}

module "container_balancer_connection_issues" {
  source = "./modules/widgets/balancer/connection-issues"

  count = length(local.balancer_connection_issues)

  # coordinates
  coordinates = local.balancer_connection_issues[count.index].coordinates

  # stats
  period = local.balancer_connection_issues[count.index].period

  # balancer
  balancer_arn  = try(local.balancer_connection_issues[count.index].balancer_arn, null)
  balancer_name = try(local.balancer_connection_issues[count.index].balancer_name, null)

  account_id = try(local.balancer_connection_issues[count.index].accountId, data.aws_caller_identity.project.account_id)

  anomaly_detection = try(local.balancer_connection_issues[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.balancer_connection_issues[count.index].anomaly_deviation, 6)
}
