# Security Hub alerts send to Teams
module "this" {
  source = "../../"

  name = "test-slack"

  create_slack_target = true

  lambda_environment_variables = {
    SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/"
  }
}
