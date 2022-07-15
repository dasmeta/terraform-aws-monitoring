module "alert-notify-slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "4.18.0"

  count = var.slack_hook_url != "" && var.slack_channel != "" && var.slack_channel != "" ? 1 : 0

  sns_topic_name                         = "${replace(var.alarm_name, ".", "-")}-slack"
  slack_webhook_url                      = var.slack_hook_url
  slack_channel                          = var.slack_channel
  slack_username                         = var.slack_username
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  lambda_function_name                   = "${replace(var.alarm_name, ".", "-")}-slack"
}
