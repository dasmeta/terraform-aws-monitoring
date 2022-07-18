module "alert_notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "4.18.0"

  count = var.sns_subscription.slack_webhook_url != "" && var.sns_subscription.slack_channel != "" && var.sns_subscription.slack_username != "" ? 1 : 0

  sns_topic_name                         = "${replace(var.alarm_name, ".", "-")}-slack"
  slack_webhook_url                      = var.sns_subscription.slack_webhook_url
  slack_channel                          = var.sns_subscription.slack_channel
  slack_username                         = var.sns_subscription.slack_username
  cloudwatch_log_group_retention_in_days = var.sns_subscription.cloudwatch_log_group_retention_in_days
  lambda_function_name                   = "${replace(var.alarm_name, ".", "-")}-slack"
}
