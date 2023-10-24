module "sns-to-teams" {
  source = "../../"

  topic_name = "test-topic"

  fallback_email_addresses = ["devops@dasmeta.com"]
  fallback_phone_numbers   = ["+374 00 000 000"]
  teams_webhooks           = ["webhook"]
  enable_dead_letter_queue = false
  recreate_missing_package = false
}


module "sns-to-teams-with-jira" {
  source = "../../"

  topic_name = "test-topic"

  fallback_email_addresses = ["devops@dasmeta.com"]
  fallback_phone_numbers   = ["+374 00 000 000"]
  teams_webhooks           = ["webhook"]
  enable_dead_letter_queue = false
  recreate_missing_package = false

  jira_config = {
    enable         = true
    url            = "url"
    key            = "key"
    user_username  = "devops"
    user_api_token = "devops_user_api_token"
  }
}
