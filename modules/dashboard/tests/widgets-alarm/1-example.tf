module "dashboard-with-alarm-metrics" {
  source = "../../"
  name   = "dashboard-with-alarm-metrics"
  rows = [
    [
      {
        type       = "alarm/status",
        title      = "Alarms status Widget",
        alarm_arns = local.alert_arns,
        width      = 24
        height     = 3
      }
    ],
    [
      {
        type      = "alarm/metric",
        alarm_arn = local.alert_arns[0]
        width     = 8
      },
      {
        type      = "alarm/metric",
        alarm_arn = local.alert_arns[1]
        width     = 8
      },
      {
        type      = "alarm/metric",
        alarm_arn = local.alert_arns[2]
        width     = 8
      }
    ]
  ]
}
