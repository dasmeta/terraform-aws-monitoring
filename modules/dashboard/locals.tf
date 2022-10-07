locals {
  # this will walk through every widget and add row/column + merge with default values
  widget_config_with_raw_column_data_and_defaults = [
    for row_number, row in var.rows : [
      for column_number, column in row : merge(
        local.widget_default_values,
        column,
        {
          row          = row_number,
          column       = column_number,
          row_count    = length(var.rows),
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
}
