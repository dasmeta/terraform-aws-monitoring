locals {
  # default values from module and provided from outside
  widget_default_values = merge(
    {
      region    = "eu-central-1"
      period    = 300
      namespace = "default"
      width     = 6
      height    = 6
    },
    var.defaults
  )

  # necessary to always have at least empty list for each widget
  widget_defaults = {
    "container/cpu" : []
    "container/memory" : []
    "container/network" : []
    "container/restarts" : []
    "balancer/2xx" : []
    "balancer/4xx" : []
    "balancer/5xx" : []
    "text/title" : []
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
    module.text_title.*.data
  )
}
