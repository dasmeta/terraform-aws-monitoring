# application widgets
module "widget_application" {
  source = "./modules/widgets/application"

  count = length(local.application)

  # coordinates
  coordinates = local.application[count.index].coordinates

  # stats
  period = local.application[count.index].period
  stat   = local.application[count.index].stat

  # metric
  title     = local.application[count.index].title
  cluster   = local.application[count.index].cluster
  namespace = local.application[count.index].namespace
  container = local.application[count.index].container

  metrics                  = local.application[count.index].metrics
  custom_dimension_metrics = try(local.application[count.index].custom_dimension_metrics, [])

  account_id        = try(local.application[count.index].accountId, null)
  anomaly_detection = try(local.application[count.index].anomaly_detection, false)
}
