output "alert_data" {
  value = {
    metric-alarms          = module.cloudwatch_metric-alarm
    log-based-metric-alarm = module.cloudwatch_log-based-metric-alarm
  }
}
