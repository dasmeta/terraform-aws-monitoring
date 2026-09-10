module "this" {
  source = "../../"

  name_prefix   = "example-alarm"
  sns_topic_arn = aws_sns_topic.alerts.arn

  canaries = {
    failing-endpoint = {
      check_type   = "soap_wsdl"
      endpoint_url = "https://httpbin.org/status/500"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
  }
}
