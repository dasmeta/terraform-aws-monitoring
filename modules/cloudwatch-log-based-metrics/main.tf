resource "aws_cloudwatch_log_metric_filter" "metric_filter" {
  for_each = { for mp in var.metrics_patterns : mp.name => mp }

  name           = each.value.name
  pattern        = each.value.pattern
  log_group_name = coalesce(each.value.log_group_name, var.log_group_name)

  metric_transformation {
    name          = each.value.name
    namespace     = var.metrics_namespace
    value         = each.value.value
    default_value = each.value.default_value
    unit          = each.value.unit
    dimensions    = each.value.dimensions
  }
}
