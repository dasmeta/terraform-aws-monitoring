module "sns-to-jira" {
  source = "../../"

  topic_name = "test-topic"

  fallback_email_addresses = ["devops@dasmeta.com"]
  fallback_phone_numbers   = ["+374 00 000 000"]
  enable_dead_letter_queue = false
  recreate_missing_package = false

  teams_webhooks = ["webhook"]
  jira_config = [{
    url            = "url"
    key            = "key"
    user_username  = "devops"
    user_api_token = "devops_user_api_token"
  }]
}
