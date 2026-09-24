module "this" {
  source    = "../../"
  sns_topic = aws_sns_topic.tets_topic_for_alarm_actions.name

  health_checks = [
    {
      host = "example.com"
    },
    {
      host = "example.com"
      path = "/12345"
    },
    {
      host = "example.com"
      path = "/api"
      percentage = {
        statistic           = "min"
        period              = "300"
        evaluation_periods  = 5
        datapoints_to_alarm = 5
      }
    },
    {
      host              = "example.com"
      failure_threshold = 5
      percentage = {
        threshold = "50"
      }
    },
    {
      host = "example.com"
      port = 80
      percentage = {
        statistic           = "min"
        equation            = "lt"
        threshold           = "1"
        period              = "300"
        evaluation_periods  = 5
        datapoints_to_alarm = 5
      }
      main = {
        statistic           = "max"
        equation            = "gt"
        threshold           = "75"
        period              = "300"
        evaluation_periods  = 5
        datapoints_to_alarm = 5
      }
    }
  ]
}
