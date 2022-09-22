module "lambda" {
  source  = "raymondbutcher/lambda-builder/aws"
  version = "1.1.0"

  function_name = coalesce(var.name, "${substr(var.name, 0, 45)}-to-servicenow")
  handler       = "lambda.lambda_handler"
  runtime       = "python3.8"
  memory_size   = var.memory_size
  timeout       = var.timeout

  build_mode = "FILENAME"
  source_dir = "${path.module}/src"
  filename   = "${path.module}/package.zip"

  role_cloudwatch_logs = true

  environment = {
    variables = var.envs
  }
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  count = var.create_alarm ? 1 : 0

  alarm_name        = "${module.lambda.function_name}-errors"
  alarm_description = "${module.lambda.function_name} invocation errors"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"

  dimensions = {
    FunctionName = module.lambda.function_name
  }

  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 60 * 60
  evaluation_periods  = 1

  # alarm_actions = var.alarm_actions
  # ok_actions    = var.ok_actions
}
