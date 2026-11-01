module "security_hub" {
  source = "../.."

  name = "example-security-hub"

  alarm_actions = {
    enabled = true
    slack_webhooks = [{
      hook_url = var.security_slack_webhook_url
      channel  = "security-alerts"
      username = "security-hub"
    }]
  }

  finding_delivery = {
    enabled               = true
    notification_mode     = "grouped"
    opsgenie_api_key      = var.security_opsgenie_api_key
    opsgenie_alert_prefix = "Example"
  }

  delivery_failure = {
    owner       = "security-operations"
    runbook_url = var.security_runbook_url
  }
}
