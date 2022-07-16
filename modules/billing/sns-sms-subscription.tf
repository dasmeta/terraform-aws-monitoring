resource "aws_sns_topic" "alerts-notify-sms" {
  count = length(var.sns_subscription.sns_subscription_phone_number_list) > 0 ? 1 : 0

  name = "${replace(var.metric_alarm_billing.alarm_name, ".", "-")}-sms"
  delivery_policy = var.delivery_policy
}

resource "aws_sns_topic_subscription" "sms" {
  count = length(var.sns_subscription.sns_subscription_phone_number_list)

  topic_arn = aws_sns_topic.alerts-notify-sms[0].arn
  protocol  = "sms"
  endpoint  = element(var.sns_subscription.sns_subscription_phone_number_list, count.index)
}
