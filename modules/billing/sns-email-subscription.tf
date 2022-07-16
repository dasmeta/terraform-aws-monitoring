resource "aws_sns_topic" "alerts-notify-email" {
  count = length(var.sns_subscription.sns_subscription_email_address_list) > 0 ? 1 : 0

  name = "${replace(var.metric_alarm_billing.alarm_name, ".", "-")}-email"
  delivery_policy = var.delivery_policy
}

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.sns_subscription.sns_subscription_email_address_list)
  topic_arn = aws_sns_topic.alerts-notify-email[0].arn
  protocol  = "email"
  endpoint  = element(var.sns_subscription.sns_subscription_email_address_list, count.index)
}
