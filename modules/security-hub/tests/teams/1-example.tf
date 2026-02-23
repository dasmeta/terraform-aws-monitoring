# Security Hub alerts send to Teams
module "this" {
  source = "../../"

  name = "test-teams"

  alarm_actions = {
    enabled        = true
    teams_webhooks = [var.teams_webhook_url]
  }
}
