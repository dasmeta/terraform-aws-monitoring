module "lambda" {
  count = var.create_teams_target ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "5.2.0"

  create        = true
  function_name = var.name
  handler       = "lambda.handler"
  runtime       = "python3.7"

  create_package          = false
  ignore_source_code_hash = true
  local_existing_package  = local.lambda_function_output_path_teams
  allowed_triggers = {
    EventBridge = {
      principal  = "events.amazonaws.com"
      source_arn = "arn:aws:events:eu-central-1:${data.aws_caller_identity.current.id}:rule/${var.name}"
    }
  }
  role_name             = var.name
  create_role           = true
  publish               = true
  environment_variables = var.lambda_environment_variables

  depends_on = [
    aws_cloudwatch_event_rule.securityhub,
    aws_securityhub_action_target.sec-hub-target
  ]
}


module "lambda-slack" {
  count = var.create_slack_target ? 1 : 0

  source  = "terraform-aws-modules/lambda/aws"
  version = "5.2.0"

  create        = true
  function_name = var.name
  handler       = "lambda.handler"
  runtime       = "python3.7"

  create_package          = false
  ignore_source_code_hash = true
  local_existing_package  = local.lambda_function_output_path_slack
  allowed_triggers = {
    EventBridge = {
      principal  = "events.amazonaws.com"
      source_arn = "arn:aws:events:eu-central-1:${data.aws_caller_identity.current.id}:rule/${var.name}"
    }
  }
  role_name             = var.name
  create_role           = true
  publish               = true
  environment_variables = var.lambda_environment_variables

  depends_on = [
    aws_cloudwatch_event_rule.securityhub,
    aws_securityhub_action_target.sec-hub-target
  ]
}
