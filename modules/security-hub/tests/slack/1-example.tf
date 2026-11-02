module "this" {
  source = "../../"

  name = "sh-slack-test"

  alarm_actions = {
    enabled = true
    slack_webhooks = [
      {
        hook_url = var.slack_webhook_url
        channel  = var.slack_channel_name
        username = "reporter"
      }
    ]
  }
}
