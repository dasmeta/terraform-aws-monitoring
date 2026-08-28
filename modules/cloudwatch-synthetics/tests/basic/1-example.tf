module "this" {
  source = "../../"

  name_prefix   = "example-basic"
  sns_topic_arn = aws_sns_topic.alerts.arn

  canaries = {
    soap-wsdl = {
      check_type   = "soap_wsdl"
      endpoint_url = "https://example.com/service?wsdl"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }

    rest-cardinfo = {
      check_type   = "rest_cardinfo"
      endpoint_url = "https://example.com/api/cardinfo"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
  }

  default_tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
