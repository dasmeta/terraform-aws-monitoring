module "dashboard-with-log-based-metrics" {
  source = "../../"
  name   = "dashboard-with-log-based-metrics"
  rows = [
    [
      {
        type : "log-based",
        title : "container_exception_error",
        metrics : [
          {
            MetricName        = "container_exception_error"
            MetricNamespace   = "LogGroupFilter"
            anomaly_detection = true
            anomaly_deviation = 8
          }
        ]
      },
      {
        type : "log-based",
        title : "error2 and error3",
        metrics : [
          {
            MetricName  = "error2"
            ClusterName = "test"
          },
          {
            MetricName = "error3"
            account_id = "12345756765"
          }
        ]
      }
    ]
  ]
}
