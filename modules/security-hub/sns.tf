resource "aws_sns_topic" "sns-sec" {
  count = var.create_sns_target ? 1 : 0

  name            = var.name
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

resource "aws_sns_topic_policy" "default" {
  count = var.create_sns_target ? 1 : 0

  arn    = aws_sns_topic.sns-sec[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}


data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.create_sns_target ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.sns-sec[0].arn]
  }
}
