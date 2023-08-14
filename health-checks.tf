module "health-check" {
  source = "./modules/health_checks"
  count  = length(var.health_checks) > 0 ? 1 : 0

  sns_topic     = local.sns_topic_name_virginia
  health_checks = var.health_checks

  providers = {
    aws          = aws,
    aws.virginia = aws.virginia
  }
}
