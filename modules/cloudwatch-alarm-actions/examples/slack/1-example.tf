module "alarm_actions" {
  source = "../.."

  topic_name = "example-account-alarms"
  slack_webhooks = [{
    hook_url = "https://hooks.example.com/services/replace-with-secret-reference"
    channel  = "example-monitoring"
    username = "reporter"
  }]
}
