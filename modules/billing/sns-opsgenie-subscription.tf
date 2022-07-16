resource "aws_sns_topic" "alerts-notify-opsgenie" {
  count = length(var.sns_subscription.opsgenie_endpoint) > 0 ? 1 : 0

  name = "${replace(var.metric_alarm_billing.alarm_name, ".", "-")}-opsgenie"
  delivery_policy = var.delivery_policy
}

resource "aws_sns_topic_subscription" "opsgenie" {
  count = length(var.sns_subscription.opsgenie_endpoint)

  topic_arn = aws_sns_topic.alerts-notify-opsgenie[0].arn
  protocol  = "https"
  endpoint  = element(var.sns_subscription.opsgenie_endpoint, count.index)
}
