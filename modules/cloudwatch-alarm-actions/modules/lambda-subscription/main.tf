locals {
  lambda_name = substr(replace("${var.sns_topic_name}-${var.uniq_id}-${var.type}", ".", "-"), 0, 63)
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.7.1"

  create        = true
  function_name = local.lambda_name
  handler       = "lambda.handler"
  runtime       = "python3.7"
  memory_size   = var.memory_size
  timeout       = var.timeout
  publish       = true
  source_path   = "${path.module}/src/${var.type}"

  # Create and use an IAM role which can log function output to CloudWatch,
  # plus the custom policy which can copy ALB logs from S3 to CloudWatch.
  attach_cloudwatch_logs_policy     = true
  cloudwatch_logs_retention_in_days = var.log_group_retention_days
  recreate_missing_package          = var.recreate_missing_package

  # in case if this role already created use created one
  role_name   = var.role_name
  create_role = var.create_role

  environment_variables = var.environment_variables

  dead_letter_target_arn    = var.dead_letter_queue_arn
  attach_dead_letter_policy = var.attach_dead_letter_policy
}

module "subscription" {
  source  = "dasmeta/sns/aws//modules//subscription"
  version = "1.2.3"

  topic    = var.sns_topic_name
  protocol = "lambda"
  endpoint = module.lambda.lambda_function_arn
}

module "alerts" {
  source  = "dasmeta/monitoring/aws//modules/alerts"
  version = "1.3.4"

  sns_topic = var.fallback_sns_topic_name

  alerts = [
    //Lambda Errors
    {
      name   = "${local.lambda_name} Lambda Failed"
      source = "AWS/Lambda/Errors"
      filters = {
        FunctionName = "${local.lambda_name}"
      }
      period = 60
      # statistic = "sum"
      # threshold = 70
    }
  ]
}
