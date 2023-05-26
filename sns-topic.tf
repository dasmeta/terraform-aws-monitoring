locals {
  sns_topic_name                = "${var.sns_topic_name}-${var.region}"
  sns_topic_application_channel = "${var.sns_topic_name}-application"
  sns_topic_name_virginia       = "${var.sns_topic_name}-virginia"
}

module "sns-to-teams-application-channel" {
  count = var.create_application_channel ? 1 : 0

  source = "./modules/cloudwatch-alarm-actions/"

  topic_name = local.sns_topic_application_channel

  fallback_email_addresses = var.fallback_email_addresses
  fallback_phone_numbers   = var.fallback_phone_numbers
  teams_webhooks           = [var.application_channel_webhook_url]
  enable_dead_letter_queue = false
  recreate_missing_package = false
}

module "sns-to-teams" {
  count = var.create_alerts ? 1 : 0

  source = "./modules/cloudwatch-alarm-actions/"

  topic_name = local.sns_topic_name

  fallback_email_addresses = var.fallback_email_addresses
  fallback_phone_numbers   = var.fallback_phone_numbers
  teams_webhooks           = [var.webhook_url]
  enable_dead_letter_queue = false
  recreate_missing_package = false
}

module "sns-to-teams-virginia" {
  count = length(var.health_checks) > 0 ? 1 : 0

  source = "./modules/cloudwatch-alarm-actions/"

  topic_name = local.sns_topic_name_virginia

  fallback_email_addresses = var.fallback_email_addresses
  fallback_phone_numbers   = var.fallback_phone_numbers
  teams_webhooks           = [var.webhook_url]
  enable_dead_letter_queue = false
  recreate_missing_package = false
  providers = {
    aws = aws.virginia
  }
}
