variable "webhook" {
  type = string
  description = "to send notification to opsgenie"
}
resource "aws_sns_topic" "sns-sec" {
  name            = "send-to-opsgenie"
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

resource "aws_sns_topic_subscription" "sns-sec-sub" {
    topic_arn = aws_sns_topic.sns-sec.arn
    protocol = "https"
    endpoint = var.webhook
}