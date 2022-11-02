# custom widgets
module "widget_custom" {
  source = "./modules/widgets/custom"

  count = length(local.custom)

  # coordinates
  coordinates = local.custom[count.index].coordinates

  # stats
  period = local.custom[count.index].period

  # metric
  title = local.custom[count.index].title

  metrics = local.custom[count.index].metrics

  account_id        = try(local.custom[count.index].accountId, data.aws_caller_identity.project.account_id)
  anomaly_detection = try(local.custom[count.index].anomaly_detection, false)
}
