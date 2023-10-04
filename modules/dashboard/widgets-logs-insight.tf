# Logs insight logs widgets
module "widget_logs_insight_logs" {
  source = "./modules/widgets/logs-insight/logs"

  count = length(local.logs_insight_logs)

  # coordinates
  coordinates = local.logs_insight_logs[count.index].coordinates

  # metric
  title = local.logs_insight_logs[count.index].title

  sources = local.logs_insight_logs[count.index].sources
  query   = local.logs_insight_logs[count.index].query

  account_id        = try(local.logs_insight_logs[count.index].accountId, null)
  anomaly_detection = try(local.logs_insight_logs[count.index].anomaly_detection, false)
}

# Logs insight metric widgets
module "widget_logs_insight_metric" {
  source = "./modules/widgets/logs-insight/metric"

  count = length(local.logs_insight_metric)

  platform = var.platform
  # grafana dashboard platform specific params
  data_source_uid = var.data_source_uid # TODO: for now this is global variable but it can be refactored and passed also per metric


  # coordinates
  coordinates = local.logs_insight_metric[count.index].coordinates

  # metric
  title = local.logs_insight_metric[count.index].title
  view  = try(local.logs_insight_metric[count.index].view, "timeSeries")

  sources     = local.logs_insight_metric[count.index].sources
  stats       = local.logs_insight_metric[count.index].stats
  query       = local.logs_insight_metric[count.index].query
  time_period = try(local.logs_insight_metric[count.index].time_period, "5m")
  stacked     = try(local.logs_insight_metric[count.index].stacked, false)

  account_id        = try(local.logs_insight_metric[count.index].accountId, null)
  anomaly_detection = try(local.logs_insight_metric[count.index].anomaly_detection, false)
}
