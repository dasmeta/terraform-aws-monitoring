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
    # Optional: supply a complete, frequently refreshed running-pod snapshot.
    # deployment_inventory = {
    #   bucket            = "example-security-image-inventory"
    #   key               = "running-pods.json"
    #   kms_key_arn       = "arn:aws:kms:eu-central-1:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab" # Only for SSE-KMS with a customer-managed key.
    #   max_age_seconds   = 900
    #   required_clusters = ["eks-dev", "eks-prod"]
    # }
  }

}
