module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.7.1"

  create        = true
  function_name = substr(replace("${var.sns_topic_name}-${var.uniq_id}-${var.type}", ".", "-"), 0, 63)
  handler       = "lambda.handler"
  runtime       = var.runtime
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
  count   = var.sns_subscription ? 1 : 0

  topic    = var.sns_topic_name
  protocol = "lambda"
  endpoint = module.lambda.lambda_function_arn
}

module "subscription-s3-sns-destination" {

  source = "./s3-subscription-sns-destination/"
  count  = var.sns_subscription ? 0 : 1

  lambda_function_arn = module.lambda.lambda_function_arn
  s3_bucket           = var.s3_bucket
  sns_topic_arn       = var.sns_topic_arn
  role_name           = var.role_name

  depends_on = [
    module.lambda
  ]
}
