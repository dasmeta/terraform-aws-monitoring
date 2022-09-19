locals {
  merged_config = [for item in var.dashboards : concat(
    module.container_cpu_widget[item.name].widget,
    module.container_memory_widget[item.name].widget,
    module.container_network_widget[item.name].widget,
    module.container_restarts_widget[item.name].widget,
    module.container_traffic_widget[item.name].widget,
    module.text[item.name].widget
    )
  ]

}
