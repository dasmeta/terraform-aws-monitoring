resource "aws_cloudwatch_log_subscription_filter" "subscription_filter" {
  for_each = { for log_name in var.cloudwatch_log_group_names : log_name => log_name }

  name            = "${var.name}_${each.value}"
  log_group_name  = each.value
  filter_pattern  = ""
  destination_arn = module.lambda.lambda_function_arn

  depends_on = [
    aws_lambda_permission.cloudwatch_permission_to_trigger_lambda
  ]
}

resource "aws_lambda_permission" "cloudwatch_permission_to_trigger_lambda" {
  for_each = { for log_name in var.cloudwatch_log_group_names : log_name => log_name }

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_function_arn
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${each.value}:*"
}
