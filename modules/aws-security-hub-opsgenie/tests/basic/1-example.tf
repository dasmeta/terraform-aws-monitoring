module "this" {
  source = "../../"

  securityhub_action_target_name         = "test-sh"
  sns_topic_name                         = "test-sns"
  opsgenie_webhook                       = "https://example.com"
  enable_security_hub                    = false
  enable_security_hub_finding_aggregator = false
}
