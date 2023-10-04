module "aws_cloudwatch_log_metric_filter" {
  source  = "dasmeta/modules/aws//modules/cloudwatch-log-metric"
  version = "1.7.0"

  for_each = { for item in var.log_base_metrics : item.name => item if var.enable_log_base_metrics }

  name             = each.value.name
  filter_pattern   = each.value.filter
  create_log_group = lookup(each.value, "create_log_group", false)
  log_group_name   = each.value.log_group_name
  metric_name      = each.value.name
}
