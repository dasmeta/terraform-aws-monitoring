# Security Hub alerts send to Teams
# Cross-account Security Hub member configuration example
module "this" {
  source = "../../"

  name = "test-teams"

  securityhub_members = {
    # email and account id
    "dasmeta.com" = "123456789123"
  }

  alarm_actions = {
    enabled        = true
    teams_webhooks = [var.teams_webhook_url]
  }
}
