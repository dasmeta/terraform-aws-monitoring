resource "aws_sns_topic" "alerts_notify_sms" {
  count = length(var.sns_subscription.sns_subscription_phone_number_list)

  name            = "${replace(var.alarm_name, ".", "-")}-sms"
  delivery_policy = var.delivery_policy
}

resource "aws_sns_topic_subscription" "sms" {
  count = length(var.sns_subscription.sns_subscription_phone_number_list)

  topic_arn = aws_sns_topic.alerts_notify_sms[0].arn
  protocol  = "sms"
  endpoint  = element(var.sns_subscription.sns_subscription_phone_number_list, count.index)
}
