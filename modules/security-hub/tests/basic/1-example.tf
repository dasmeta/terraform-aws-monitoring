# Security Hub alerts send to email

module "this" {
  source = "../../"

  name                   = "test-email"
  sns_email_subscription = "devops@dasmeta.com"
  create_sns_target      = true
}
