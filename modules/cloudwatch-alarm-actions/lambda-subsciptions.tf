data "aws_region" "current" {}

# slack notify subscription
module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "5.4.1"

  for_each = { for webhook in var.slack_webhooks : "${webhook.channel}-${webhook.username}" => webhook }

  # sns/subscription configs
  sns_topic_name       = module.topic.name
  create_sns_topic     = false
  lambda_function_name = substr(replace("${each.value.channel}-${each.value.username}-slack", ".", "-"), 0, 63)

  # lambda configs
  slack_webhook_url = each.value.hook_url
  slack_channel     = each.value.channel
  slack_username    = each.value.username

  recreate_missing_package               = var.recreate_missing_package
  cloudwatch_log_group_retention_in_days = var.log_group_retention_days
  lambda_dead_letter_target_arn          = try(module.dead_letter_queue[0].queue_arn, null)
  lambda_attach_dead_letter_policy       = var.enable_dead_letter_queue
}

# servicenow notify subscription
module "notify_servicenow" {
  source = "./modules/lambda-subscription"

  for_each = { for webhook in var.servicenow_webhooks : "${webhook.domain}-${webhook.path}" => webhook }

  # sns/subscription configs
  sns_topic_name = module.topic.name

  # lambda configs
  uniq_id = "${each.value.domain}-${each.value.path}}"
  type    = "servicenow"
  environment_variables = {
    SERVICENOW_DOMAIN = each.value.domain
    SERVICENOW_PATH   = each.value.path
    SERVICENOW_USER   = each.value.user
    SERVICENOW_PASS   = each.value.pass
  }

  recreate_missing_package  = var.recreate_missing_package
  log_group_retention_days  = var.log_group_retention_days
  dead_letter_queue_arn     = try(module.dead_letter_queue[0].queue_arn, null)
  attach_dead_letter_policy = var.enable_dead_letter_queue

  depends_on = [
    module.topic # TODO: seems there is no need on this dependency, but without this it fails on getting topic by name in underlying subscription module, please check and get right solution of this
  ]
}

# teams notify subscription
module "notify_teams" {
  source = "./modules/lambda-subscription"

  for_each = { for key, webhook in var.teams_webhooks : key => webhook }

  # sns/subscription configs
  sns_topic_name = module.topic.name

  # lambda configs
  uniq_id = each.key
  type    = "teams"
  environment_variables = {
    WEBHOOK_URL = each.value
    REGION      = data.aws_region.current.name
    LOG_LEVEL   = var.log_level
  }

  recreate_missing_package  = var.recreate_missing_package
  log_group_retention_days  = var.log_group_retention_days
  dead_letter_queue_arn     = try(module.dead_letter_queue[0].queue_arn, null)
  attach_dead_letter_policy = var.enable_dead_letter_queue

  depends_on = [
    module.topic # TODO: seems there is no need on this dependency, but without this it fails on getting topic by name in underlying subscription module, please check and get right solution of this
  ]
}
