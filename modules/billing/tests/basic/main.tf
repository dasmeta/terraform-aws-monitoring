module "monitoring_billing" {
  source = "../../"

  name           = "Account Monthly Budget"
  limit_amount   = "4000"
  thresholds     = ["40", "60", "80", "90", "100", "110"]
  sns_topic_arns = ["arn:aws:sns:eu-central-1:00000000:accounts_events"]
}
