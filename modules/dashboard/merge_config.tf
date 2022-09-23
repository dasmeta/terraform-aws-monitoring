locals {
  merged_config = concat(
    // All_Widget
    flatten(module.all_widget[*].widget),

    // Widget/Text
    module.text.widget
  )
}
