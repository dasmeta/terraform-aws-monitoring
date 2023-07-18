# Security Hub alerts send to Teams
module "this" {
  source = "../../"

  name = "test-teams"

  create_teams_target = true
  securityhub_members = {
    // email and account id
    "dasmeta.com" = "123456789123"
  }

  lambda_environment_variables = {
    WEBHOOK_URL = "https://hypoportsystems.webhook.office.com/webhookb2//IncomingWebhook/"
  }
}
