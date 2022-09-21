locals {
  merged_config = concat(

    // Widget/Container
    module.container_cpu_widget.widget,
    module.container_memory_widget.widget,
    module.container_network_widget.widget,
    module.container_restarts_widget.widget,

    // Widget/Traffic
    module.container_traffic_5xx_widget.widget,
    module.container_traffic_4xx_widget.widget,
    module.container_traffic_2xx_widget.widget,

    // Widget/Text
    module.text.widget
  )
}
