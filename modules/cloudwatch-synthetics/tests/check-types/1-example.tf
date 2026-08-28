module "this" {
  source = "../../"

  name_prefix   = "example-types"
  sns_topic_arn = aws_sns_topic.alerts.arn

  canaries = {
    soap-wsdl = {
      check_type   = "soap_wsdl"
      endpoint_url = "https://example.com/wsdl"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
    soap-cardinfo = {
      check_type   = "soap_cardinfo"
      endpoint_url = "https://example.com/soap/cardinfo"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
    rest-cardinfo = {
      check_type   = "rest_cardinfo"
      endpoint_url = "https://example.com/rest/cardinfo"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
    blackhawk = {
      check_type   = "blackhawk_management"
      endpoint_url = "https://example.com/blackhawk/management"
      secret_arn   = aws_secretsmanager_secret.example.arn
      schedule     = "rate(5 minutes)"
    }
  }
}
