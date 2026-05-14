locals {
  sns_topic_name          = var.sns_topic_name
  sns_topic_name_virginia = "${var.sns_topic_name}-virginia"
  alarm_client_name       = trimspace(var.client_name != null ? var.client_name : "") != "" ? var.client_name : null
}

module "health-check" {
  source = "./modules/alerts/"
  count  = length(var.health_checks) > 0 ? 1 : 0

  sns_topic = local.sns_topic_name_virginia

  health_checks = var.health_checks
  client_name   = local.alarm_client_name

  providers = {
    aws = aws.virginia
  }
}


module "alerts" {
  source = "./modules/alerts/"

  count = var.create_alerts ? 1 : 0

  sns_topic   = local.sns_topic_name
  alerts      = var.alerts
  client_name = local.alarm_client_name
}

module "alerts_slo_sli_sla" {
  source = "./modules/alerts/"

  count = var.expression_alert != {} ? 1 : 0

  sns_topic        = local.sns_topic_name
  expression_alert = var.expression_alert
  client_name      = local.alarm_client_name

  enable_insufficient_data_actions = false
  enable_ok_actions                = false
}
