resource "aws_cloudwatch_dashboard" "dashboards" {
  dashboard_name = var.name
  dashboard_body = <<EOF
  {
    "widgets": ${jsonencode(local.merged_config)}
  }
  EOF
}
