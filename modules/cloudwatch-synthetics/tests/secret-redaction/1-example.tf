module "this" {
  source = "../../"

  name_prefix   = "example-redact"
  sns_topic_arn = aws_sns_topic.alerts.arn

  canaries = {
    forced-failure = {
      check_type   = "blackhawk_management"
      endpoint_url = "https://httpbin.org/status/500"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
  }
}
