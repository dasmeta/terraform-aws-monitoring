module "sns-to-teams" {
  source = "../../"

  topic_name = "test-topic"

  fallback_email_addresses = ["devops@dasmeta.com"]
  fallback_phone_numbers   = ["+374 00 000 000"]
  teams_webhooks           = ["webhook"]
  enable_dead_letter_queue = false
  recreate_missing_package = false
}
