# Security Hub alerts send to Teams
module "this" {
  source = "../../"

  name = "test-teams"

  create_teams_target = true
  lambda_environment_variables = {
    WEBHOOK_URL = "https://hypoportsystems.webhook.office.com/webhookb2//IncomingWebhook/"
  }
}
