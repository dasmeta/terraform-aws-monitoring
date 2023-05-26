module "health-check" {
  source = "./modules/alerts/"
  count  = length(var.health_checks) > 0 ? 1 : 0

  sns_topic = local.sns_topic_name_virginia

  health_checks = var.health_checks

  providers = {
    aws = aws.virginia
  }
}


module "alerts" {
  source = "./modules/alerts/"

  count = var.create_alerts ? 1 : 0

  sns_topic = local.sns_topic_name
  alerts    = var.alerts
}


module "alerts_application_channel" {
  source = "./modules/alerts/"

  count = var.create_application_channel ? 1 : 0

  sns_topic = local.sns_topic_name
  alerts    = var.application_channel_alerts
}
