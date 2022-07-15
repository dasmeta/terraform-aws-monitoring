resource "aws_sns_topic" "alerts-notify-email" {
  count = length(var.sns_subscription_email_address_list) > 0 ? 1 : 0

  name = "${replace(var.alarm_name, ".", "-")}-email"
  delivery_policy = <<EOF
  {
    "http": {
      "defaultHealthyRetryPolicy": {
        "minDelayTarget": 20,
        "maxDelayTarget": 20,
        "numRetries": 3,
        "numMaxDelayRetries": 0,
        "numNoDelayRetries": 0,
        "numMinDelayRetries": 0,
        "backoffFunction": "linear"
      },
      "disableSubscriptionOverrides": false,
      "defaultThrottlePolicy": {
        "maxReceivesPerSecond": 1
      }
    }
  }
  EOF

  }

resource "aws_sns_topic_subscription" "email" {
  count     = length(var.sns_subscription_email_address_list)
  topic_arn = aws_sns_topic.alerts-notify-email[0].arn
  protocol  = "email"
  endpoint  = element(var.sns_subscription_email_address_list, count.index)
}
