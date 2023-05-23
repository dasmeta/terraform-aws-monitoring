module "this" {
  source     = "../../"
  topic_name = "cloudwatch-alarm"

  teams_webhooks           = ["https://hypoportsystems.webhook.office.com/webhookb2/0b0ea93a-4ad2-4f72-9467-b7ab3ddbd44a@8899db84-419b-4a2f-a612-4b819ec57add/IncomingWebhook/2a79b3c78dad404aa0a5243bdd850fd0/bdf31ab3-ccb7-47d6-b067-81d4dc197d53"]
  enable_dead_letter_queue = false
  fallback_email_addresses = ["julia@dasmeta.com"]
  fallback_phone_numbers   = ["+37491412414"]
}

# output "id" {
#   value = module.this.id
# }
