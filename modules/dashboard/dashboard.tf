resource "aws_cloudwatch_dashboard" "dashboards" {
  for_each = { for item in var.dashboards : item.name => item }

  dashboard_name = each.key
  dashboard_body = <<EOF
  {
    "widgets": ${jsonencode(local.merged_config[0])}
  }
  EOF
}
