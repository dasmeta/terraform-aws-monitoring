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
      port = 80
    }
  ]

  providers = {
    aws         = aws
    aws.logging = aws
  }
}
