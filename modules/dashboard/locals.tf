output "debug" {
  description = "description"
  value = {

  }
}

locals {
  dashboard_title = "${var.account_id_as_name_prefix ? "${data.aws_caller_identity.project.account_id}-" : ""}${var.name}"

  # default values from module and provided from outside
  widget_default_values = merge(
    {
      region            = "eu-central-1"
      period            = 60
      stat              = "Sum"
      namespace         = "default"
      width             = 6
      height            = 6
      anomaly_detection = false
      anomaly_deviation = 6
      expressions       = []
      yAxis             = { left = { min = 0 } }
    },
    var.defaults
  )

  # necessary to always have at least empty list for each widget
  widget_defaults = {
    "container/cpu"                    = []
    "container/memory"                 = []
    "container/network"                = []
    "container/network-in"             = []
    "container/network-out"            = []
    "container/restarts"               = []
    "container/replicas"               = []
    "container/request-count"          = []
    "container/response-time"          = []
    "container/external-health-check"  = []
    "container/error-rate"             = []
    "container/all-requests"           = []
    "container/health-check"           = []
    "container/release-version"        = []
    "balancer/2xx"                     = []
    "balancer/4xx"                     = []
    "balancer/5xx"                     = []
    "balancer/traffic"                 = []
    "balancer/response-time"           = []
    "balancer/unhealthy-request-count" = []
    "balancer/request-count"           = []
    "balancer/all-requests"            = []
    "balancer/error-rate"              = []
    "balancer/connection-issues"       = []
    "text/title"                       = []
    "text/title-with-link"             = []
    "log-based"                        = []
    "custom"                           = []
    "application"                      = []
    "logs-insight/logs"                = []
    "logs-insight/metric"              = []
    "alarm/status"                     = []
    "alarm/metric"                     = []
    "sla-slo-sli"                      = []
    "rds/cpu"                          = []
    "rds/memory"                       = []
    "rds/disk"                         = []
    "rds/connections"                  = []
    "rds/network"                      = []
    "rds/iops"                         = []
    "rds/performance"                  = []
    "rds/free-storage"                 = []
    "rds/swap"                         = []
    "rds/disk-latency"                 = []
    "redis/cache-hit"                  = []
    "redis/capacity"                   = []
    "redis/cpu"                        = []
    "redis/current-connections"        = []
    "redis/latency"                    = []
    "redis/memory"                     = []
    "redis/network"                    = []
    "redis/new-connections"            = []
    "cloudfront/errors"                = []
    "cloudfront/error-rate"            = []
    "cloudfront/traffic-bytes"         = []
    "cloudfront/requests"              = []
    "dns/queries-gauge"                = []
    "dns/queries-chart"                = []
    # "blocks/container"                 = []
  }

  # filter out all blocks see local.blocks

  # load data from blocks (call modules)
  # merge/replace data from rows with results from blocks
  # widget_config_with_block_merge = var.rows # replace this with loading data from block modules

  # this will walk through every widget and add row/column + merge with default values
  widget_config_with_raw_column_data_and_defaults = [
    for row_number, row in local.rows : [
      for column_number, column in row : merge(
        local.widget_default_values,
        column,
        {
          row          = row_number,
          column       = column_number,
          row_count    = length(local.rows),
          column_count = length(row)
        }
      )
    ]
  ]

  widget_config = merge(
    local.widget_defaults,
    // groups rows by widget type
    { for key, item in flatten(local.widget_config_with_raw_column_data_and_defaults) :
      item.type => merge(
        item,
        # calculate coordinates based on defaults and row/column details
        {
          coordinates = {
            x      = item.column * item.width
            y      = item.row
            width  = item.width
            height = item.height
          }
        }
    )... }
  )

  # widget aliases
  container_cpu                   = local.widget_config["container/cpu"]
  container_memory                = local.widget_config["container/memory"]
  container_network               = local.widget_config["container/network"]
  container_network_in            = local.widget_config["container/network-in"]
  container_network_out           = local.widget_config["container/network-out"]
  container_restarts              = local.widget_config["container/restarts"]
  container_replicas              = local.widget_config["container/replicas"]
  container_request_count         = local.widget_config["container/request-count"]
  container_response_time         = local.widget_config["container/response-time"]
  container_external_health_check = local.widget_config["container/external-health-check"]
  container_error_rate            = local.widget_config["container/error-rate"]
  container_all_requests          = local.widget_config["container/all-requests"]
  container_health_check          = local.widget_config["container/health-check"]
  container_release_version       = local.widget_config["container/release-version"]

  balancer_2xx                     = local.widget_config["balancer/2xx"]
  balancer_4xx                     = local.widget_config["balancer/4xx"]
  balancer_5xx                     = local.widget_config["balancer/5xx"]
  balancer_traffic                 = local.widget_config["balancer/traffic"]
  balancer_response_time           = local.widget_config["balancer/response-time"]
  balancer_unhealthy_request_count = local.widget_config["balancer/unhealthy-request-count"]
  balancer_request_count           = local.widget_config["balancer/request-count"]
  balancer_all_requests            = local.widget_config["balancer/all-requests"]
  balancer_error_rate              = local.widget_config["balancer/error-rate"]
  balancer_connection_issues       = local.widget_config["balancer/connection-issues"]

  text_title           = local.widget_config["text/title"]
  text_title_with_link = local.widget_config["text/title-with-link"]

  log_based   = local.widget_config["log-based"]
  custom      = local.widget_config["custom"]
  application = local.widget_config["application"]

  rds_cpu          = local.widget_config["rds/cpu"]
  rds_memory       = local.widget_config["rds/memory"]
  rds_disk         = local.widget_config["rds/disk"]
  rds_connections  = local.widget_config["rds/connections"]
  rds_network      = local.widget_config["rds/network"]
  rds_iops         = local.widget_config["rds/iops"]
  rds_performance  = local.widget_config["rds/performance"]
  rds_free_storage = local.widget_config["rds/free-storage"]
  rds_swap         = local.widget_config["rds/swap"]
  rds_disk_latency = local.widget_config["rds/disk-latency"]

  redis_cache_hit           = local.widget_config["redis/cache-hit"]
  redis_capacity            = local.widget_config["redis/capacity"]
  redis_cpu                 = local.widget_config["redis/cpu"]
  redis_current_connections = local.widget_config["redis/current-connections"]
  redis_latency             = local.widget_config["redis/latency"]
  redis_memory              = local.widget_config["redis/memory"]
  redis_network             = local.widget_config["redis/network"]
  redis_new_connections     = local.widget_config["redis/new-connections"]

  cloudfront_errors        = local.widget_config["cloudfront/errors"]
  cloudfront_error_rate    = local.widget_config["cloudfront/error-rate"]
  cloudfront_traffic_bytes = local.widget_config["cloudfront/traffic-bytes"]
  cloudfront_requests      = local.widget_config["cloudfront/requests"]

  dns_queries_gauge = local.widget_config["dns/queries-gauge"]
  dns_queries_chart = local.widget_config["dns/queries-chart"]

  logs_insight_logs   = local.widget_config["logs-insight/logs"]
  logs_insight_metric = local.widget_config["logs-insight/metric"]

  alarm_status = local.widget_config["alarm/status"]
  alarm_metric = local.widget_config["alarm/metric"]

  sla_slo_sli = local.widget_config["sla-slo-sli"]

  # # blocks
  # blocks_container = local.widget_config["blocks/container"]

  # combine results (last step)
  widget_result = concat(
    // Widget/Container
    module.container_cpu_widget[*].data,
    module.container_memory_widget[*].data,
    module.container_network_widget[*].data,
    module.container_network_in_widget[*].data,
    module.container_network_out_widget[*].data,
    module.container_restarts_widget[*].data,
    module.container_replicas_widget[*].data,
    module.container_request_count_widget[*].data,
    module.container_response_time_widget[*].data,
    module.container_external_health_check_widget[*].data,
    module.container_error_rate[*].data,
    module.container_all_requests[*].data,
    module.container_health_check[*].data,
    module.container_release_version[*].data,

    // Widget/Traffic
    module.container_balancer_2xx_widget[*].data,
    module.container_balancer_4xx_widget[*].data,
    module.container_balancer_5xx_widget[*].data,
    module.container_balancer_traffic_widget[*].data,
    module.container_balancer_response_time_widget[*].data,
    module.container_balancer_unhealthy_request_count_widget[*].data,
    module.container_balancer_request_count_widget[*].data,
    module.container_balancer_all_requests_widget[*].data,
    module.container_balancer_error_rate[*].data,
    module.container_balancer_connection_issues[*].data,

    // Widget/Text
    module.text_title[*].data,
    module.text_title_with_link[*].data,

    # log based metrics
    module.widget_log_based[*].data,

    # custom metrics
    module.widget_custom[*].data,

    # application/prometheus metrics
    module.widget_application[*].data,

    # RDS
    module.widget_rds_cpu[*].data,
    module.widget_rds_memory[*].data,
    module.widget_rds_disk[*].data,
    module.widget_rds_db_connections[*].data,
    module.widget_rds_network[*].data,
    module.widget_rds_iops[*].data,
    module.widget_rds_performance[*].data,
    module.widget_rds_free_storage[*].data,
    module.widget_rds_swap[*].data,
    module.widget_rds_disk_latency[*].data,

    # Redis
    module.widget_redis_cache_hit[*].data,
    module.widget_redis_capacity[*].data,
    module.widget_redis_cpu[*].data,
    module.widget_redis_current_connections[*].data,
    module.widget_redis_latency[*].data,
    module.widget_redis_memory[*].data,
    module.widget_redis_network[*].data,
    module.widget_redis_new_connections[*].data,

    # CDN
    module.widget_cloudfront_errors[*].data,
    module.widget_cloudfront_error_rate[*].data,
    module.widget_cloudfront_traffic_bytes[*].data,
    module.widget_cloudfront_requests[*].data,

    # DNS
    module.widget_dns_queries_gauge[*].data,
    module.widget_dns_queries_chart[*].data,

    # logs insights metrics/logs
    module.widget_logs_insight_logs[*].data,
    module.widget_logs_insight_metric[*].data,

    # alarm status/metrics
    module.widget_alarm_status[*].data,
    module.widget_alarm_metric[*].data,

    module.widget_sla_slo_sli[*].data,

    # # blocks
    # module.blocks_container[*].data
  )
}
