# Log based widgets
module "widget_log_based" {
  source = "./modules/widgets/log-based"

  count = length(local.log_based)

  # coordinates
  coordinates = local.log_based[count.index].coordinates

  # stats
  period = local.log_based[count.index].period

  # metric
  title = local.log_based[count.index].title

  metrics = local.log_based[count.index].metrics

  account_id        = try(local.log_based[count.index].accountId, null)
  anomaly_detection = try(local.log_based[count.index].anomaly_detection, false)
}
