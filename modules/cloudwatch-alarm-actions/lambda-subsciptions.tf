data "aws_region" "current" {}

# slack notify subscription
module "notify_slack" {
  source  = "terraform-aws-modules/notify-slack/aws"
  version = "6.7.0"

  for_each = { for webhook in var.slack_webhooks : "${webhook.channel}-${webhook.username}" => webhook }

  # sns/subscription configs
  sns_topic_name       = module.topic.name
  create_sns_topic     = false
  lambda_function_name = substr(replace("${each.value.channel}-${each.value.username}-slack", ".", "-"), 0, 63)

  # lambda configs
  slack_webhook_url = sensitive(each.value.hook_url)
  slack_channel     = each.value.channel
  slack_username    = each.value.username

  recreate_missing_package               = var.recreate_missing_package
  cloudwatch_log_group_retention_in_days = var.log_group_retention_days
  lambda_dead_letter_target_arn          = try(module.dead_letter_queue[0].queue_arn, null)
  lambda_attach_dead_letter_policy       = var.enable_dead_letter_queue
}

# Opsgenie creates the GuardDuty alert through an HTTPS subscription first. This
# Lambda then finds that alert by the EventBridge event ID and adds actionable detail.
module "notify_opsgenie_guardduty" {
  source = "./modules/lambda-subscription"
  count  = var.opsgenie_guardduty_enrichment.enabled ? 1 : 0

  sns_topic_name          = module.topic.name
  fallback_sns_topic_name = module.fallback-topic[0].name

  uniq_id = "enrich"
  type    = "opsgenie-guardduty"
  runtime = "python3.12"
  timeout = 30

  environment_variables = {
    LOG_LEVEL                           = var.log_level
    OPSGENIE_API_KEY                    = sensitive(var.opsgenie_guardduty_enrichment.api_key)
    OPSGENIE_API_URL                    = var.opsgenie_guardduty_enrichment.api_url
    OPSGENIE_ALERT_SEARCH_RETRIES       = tostring(var.opsgenie_guardduty_enrichment.alert_search_retries)
    OPSGENIE_ALERT_SEARCH_DELAY_SECONDS = tostring(var.opsgenie_guardduty_enrichment.alert_search_delay_seconds)
  }

  recreate_missing_package  = var.recreate_missing_package
  log_group_retention_days  = var.log_group_retention_days
  dead_letter_queue_arn     = try(module.dead_letter_queue[0].queue_arn, null)
  attach_dead_letter_policy = var.enable_dead_letter_queue
  lambda_failed_alert       = merge({ fill_insufficient_data = true }, var.lambda_failed_alert)

  depends_on = [module.topic]
}

# servicenow notify subscription
module "notify_servicenow" {
  source = "./modules/lambda-subscription"

  for_each = { for webhook in var.servicenow_webhooks : "${webhook.domain}-${webhook.path}" => webhook }

  # sns/subscription configs
  sns_topic_name          = module.topic.name
  fallback_sns_topic_name = module.fallback-topic[0].name

  # lambda configs
  uniq_id = "${each.value.domain}-${each.value.path}}"
  type    = "servicenow"
  environment_variables = {
    SERVICENOW_DOMAIN = each.value.domain
    SERVICENOW_PATH   = each.value.path
    SERVICENOW_USER   = each.value.user
    SERVICENOW_PASS   = sensitive(each.value.pass)
  }

  recreate_missing_package  = var.recreate_missing_package
  log_group_retention_days  = var.log_group_retention_days
  dead_letter_queue_arn     = try(module.dead_letter_queue[0].queue_arn, null)
  attach_dead_letter_policy = var.enable_dead_letter_queue

  lambda_failed_alert = var.lambda_failed_alert

  depends_on = [
    module.topic # TODO: seems there is no need on this dependency, but without this it fails on getting topic by name in underlying subscription module, please check and get right solution of this
  ]
}

# teams notify subscription
module "notify_teams" {
  source = "./modules/lambda-subscription"

  for_each = { for key, webhook in var.teams_webhooks : key => webhook }

  # sns/subscription configs
  sns_topic_name          = module.topic.name
  fallback_sns_topic_name = module.fallback-topic[0].name

  # lambda configs
  uniq_id = each.key
  type    = "teams"
  timeout = 10

  additional_script_files = [
    "${path.module}/modules/lambda-subscription/src/event_handler.py"
  ]

  environment_variables = {
    WEBHOOK_URL = sensitive(each.value)
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

module "notify_jira" {
  source = "./modules/lambda-subscription"

  for_each = { for jira in var.jira_config : jira.url => jira }

  # sns/subscription configs
  sns_topic_name          = module.topic.name
  fallback_sns_topic_name = module.fallback-topic[0].name

  # lambda configs
  uniq_id = "jira_integration"
  type    = "jira"
  timeout = 10

  additional_script_files = [
    "${path.module}/modules/lambda-subscription/src/event_handler.py"
  ]

  environment_variables = {
    JIRA_URL      = each.value.url
    JIRA_KEY      = sensitive(each.value.key)
    JIRA_PASSWORD = sensitive(each.value.user_api_token)
    JIRA_USERNAME = each.value.user_username
    REGION        = data.aws_region.current.name
  }

  recreate_missing_package  = var.recreate_missing_package
  log_group_retention_days  = var.log_group_retention_days
  dead_letter_queue_arn     = try(module.dead_letter_queue[0].queue_arn, null)
  attach_dead_letter_policy = var.enable_dead_letter_queue

  depends_on = [
    module.topic # TODO: seems there is no need on this dependency, but without this it fails on getting topic by name in underlying subscription module, please check and get right solution of this
  ]
}
