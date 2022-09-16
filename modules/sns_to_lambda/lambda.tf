resource "aws_cloudwatch_log_group" "log" {
  name              = "sns-${var.name}"
  retention_in_days = 365
}

module "sns_to_servicenow" {
  source = "./sns_to_servicenow"

  name         = var.name
  create_alarm = false

  envs = var.lambda_envs
}
