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
    "container/restarts" : []
    "traffic/5xx" : []
    "traffic/4xx" : []
    "traffic/3xx" : []
    "traffic/2xx" : []
    "text/title" : []
  }

  # this will walk through every widget and add row/column + merge with default values
  widget_config_with_raw_column_data_and_defaults = [
    for row_number, row in var.rows : [
      for column_number, column in row : merge(
        local.widget_default_values,
        column,
        {
          row : row_number,
          column : column_number,
          row_count : length(var.rows),
          column_count : length(row)
        }
      )
    ]
  ]

  # coordinates : {
  #   x : 24 / column_count * column_number,
  #   y : row_number,
  #   width : column.width,
  #   height : column.height,
  # },

  widget_config = merge(
    local.widget_defaults,
    // groups rows by widget type
    { for key, item in flatten(local.widget_config_with_raw_column_data_and_defaults) :
    item.type => merge(local.widget_default_values, item)... }
  )

  widget_result = concat(
    // Widget/Container
    module.container_cpu_widget.*.data,
    # module.container_memory_widget.widget,
    # module.container_network_widget.widget,
    # module.container_restarts_widget.widget,

    # // Widget/Traffic
    # module.container_traffic_5xx_widget.widget,
    # module.container_traffic_4xx_widget.widget,
    # module.container_traffic_2xx_widget.widget,

    // Widget/Text
    module.text_title.*.data
  )
}
