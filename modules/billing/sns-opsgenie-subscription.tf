resource "aws_sns_topic" "alerts_notify_opsgenie" {
  count = length(var.sns_subscription.opsgenie_endpoint)

  name            = "${replace(var.alarm_name, ".", "-")}-opsgenie"
  delivery_policy = var.delivery_policy
}

resource "aws_sns_topic_subscription" "opsgenie" {
  count = length(var.sns_subscription.opsgenie_endpoint)

  topic_arn = aws_sns_topic.alerts_notify_opsgenie[0].arn
  protocol  = "https"
  endpoint  = element(var.sns_subscription.opsgenie_endpoint, count.index)
}
