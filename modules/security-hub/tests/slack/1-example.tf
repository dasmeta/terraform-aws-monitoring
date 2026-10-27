module "this" {
  source = "../../"

  name             = "sh-slack-test"
  delivery_failure = var.delivery_failure

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
