# alarm status widgets
module "widget_alarm_status" {
  source = "./modules/widgets/alarm/status"

  count = length(local.alarm_status)

  # coordinates
  coordinates = local.alarm_status[count.index].coordinates

  # metric
  title = local.alarm_status[count.index].title

  alarm_arns = local.alarm_status[count.index].alarm_arns
  stacked    = try(local.alarm_status[count.index].stacked, false)

  account_id        = try(local.alarm_status[count.index].accountId, null)
  anomaly_detection = try(local.alarm_status[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.alarm_status[count.index].anomaly_deviation, 6)
}

# alarm metric widgets
module "widget_alarm_metric" {
  source = "./modules/widgets/alarm/metric"

  count = length(local.alarm_metric)

  # coordinates
  coordinates = local.alarm_metric[count.index].coordinates

  # metric
  title = try(local.alarm_metric[count.index].title, null)
  view  = try(local.alarm_metric[count.index].view, "timeSeries")

  alarm_arn = local.alarm_metric[count.index].alarm_arn
  stacked   = try(local.alarm_metric[count.index].stacked, false)

  account_id        = try(local.alarm_metric[count.index].accountId, null)
  anomaly_detection = try(local.alarm_metric[count.index].anomaly_detection, false)
  anomaly_deviation = try(local.alarm_metric[count.index].anomaly_deviation, 6)
}
