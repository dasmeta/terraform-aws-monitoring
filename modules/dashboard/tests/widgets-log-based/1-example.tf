module "dashboard-with-log-based-metrics" {
  source = "../../"
  name   = "dashboard-with-log-based-metrics"
  rows = [
    [
      {
        type : "log-based",
        title : "error1",
        metrics : [{
          MetricName = "error2"
        }]
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
