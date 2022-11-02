module "dashboard-with-logs-insight-metrics" {
  source = "../../"
  name   = "dashboard-with-logs-insight-metrics"
  rows = [
    [
      {
        type  = "logs-insight/logs",
        title = "Logs Insight logs",
        sources = [
          aws_cloudwatch_log_group.log_group_test_a.name,
          aws_cloudwatch_log_group.log_group_test_b.name,
        ],
        query = <<-EOT
            fields @timestamp, @message
            | sort @timestamp desc
            | limit 20
            EOT
        width = 12
      },
      {
        type        = "logs-insight/metric",
        title       = "Logs Insight logs",
        time_period = "5m"
        view        = "timeSeries" // valid values are "timeSeries", "bar", "pie"
        stats = [
          "avg(@timestamp) as timestamp",
          "count(*) as count"
        ]
        sources = [
          aws_cloudwatch_log_group.log_group_test_a.name,
          aws_cloudwatch_log_group.log_group_test_b.name,
        ],
        query = <<-EOT
            fields @timestamp, @message
            | sort @timestamp desc
            | limit 20
          EOT
        width = 12
      }
    ]
  ]
}