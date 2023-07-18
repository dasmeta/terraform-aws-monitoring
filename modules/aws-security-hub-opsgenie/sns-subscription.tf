resource "aws_sns_topic_subscription" "sns-to-opsgenie" {
  count = var.sns_opsgenie_subscription != "" ? 1 : 0

  topic_arn = aws_sns_topic.sns-sec[0].arn
  protocol  = "https"
  endpoint  = var.sns_opsgenie_subscription
}

resource "aws_sns_topic_subscription" "sns-to-teams" {
  count = var.sns_email_subscription != "" ? 1 : 0

  topic_arn = aws_sns_topic.sns-sec[0].arn
  protocol  = "email"
  endpoint  = var.sns_email_subscription
}
