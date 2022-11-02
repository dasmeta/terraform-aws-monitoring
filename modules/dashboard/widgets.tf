locals {
  # default values from module and provided from outside
  widget_default_values = merge(
    {
      region            = "eu-central-1"
      period            = 300
      stat              = "Sum"
      namespace         = "default"
      width             = 6
      height            = 6
      anomaly_detection = false
    },
    var.defaults
  )

  # necessary to always have at least empty list for each widget
  widget_defaults = {
    "container/cpu"       = []
    "container/memory"    = []
    "container/network"   = []
    "container/restarts"  = []
    "balancer/2xx"        = []
    "balancer/4xx"        = []
    "balancer/5xx"        = []
    "text/title"          = []
    "log-based"           = []
    "custom"              = []
    "application"         = []
    "logs-insight/logs"   = []
    "logs-insight/metric" = []
    "alarm/status"        = []
    "alarm/metric"        = []
  }

  # widget aliases
  container_cpu      = local.widget_config["container/cpu"]
  container_memory   = local.widget_config["container/memory"]
  container_network  = local.widget_config["container/network"]
  container_restarts = local.widget_config["container/restarts"]

  balancer_2xx = local.widget_config["balancer/2xx"]
  balancer_4xx = local.widget_config["balancer/4xx"]
  balancer_5xx = local.widget_config["balancer/5xx"]

  text_title = local.widget_config["text/title"]

  log_based   = local.widget_config["log-based"]
  custom      = local.widget_config["custom"]
  application = local.widget_config["application"]

  logs_insight_logs   = local.widget_config["logs-insight/logs"]
  logs_insight_metric = local.widget_config["logs-insight/metric"]

  alarm_status = local.widget_config["alarm/status"]
  alarm_metric = local.widget_config["alarm/metric"]

  # combine results
  widget_result = concat(
    // Widget/Container
    module.container_cpu_widget.*.data,
    module.container_memory_widget.*.data,
    module.container_network_widget.*.data,
    module.container_restarts_widget.*.data,

    // Widget/Traffic
    module.container_balancer_2xx_widget.*.data,
    module.container_balancer_4xx_widget.*.data,
    module.container_balancer_5xx_widget.*.data,

    // Widget/Text
    module.text_title.*.data,

    # log based metrics
    module.widget_log_based.*.data,

    # custom metrics
    module.widget_custom.*.data,

    # application/prometheus metrics
    module.widget_application.*.data,

    # logs insights metrics/logs
    module.widget_logs_insight_logs.*.data,
    module.widget_logs_insight_metric.*.data,

    # alarm status/metrics
    module.widget_alarm_status.*.data,
    module.widget_alarm_metric.*.data
  )
}
