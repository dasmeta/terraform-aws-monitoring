locals {
  merged_config = [for item in var.dashboards : concat(

    // Widget/Container
    module.container_cpu_widget[item.name].widget,
    module.container_memory_widget[item.name].widget,
    module.container_network_widget[item.name].widget,
    module.container_restarts_widget[item.name].widget,

    // Widget/Traffic
    module.container_traffic_5xx_widget[item.name].widget,
    module.container_traffic_4xx_widget[item.name].widget,
    module.container_traffic_2xx_widget[item.name].widget,

    // Widget/Text
    module.text[item.name].widget
    )
  ]

}
