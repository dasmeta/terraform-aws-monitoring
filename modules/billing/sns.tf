resource "aws_sns_topic" "billing_alarm_topic" {
  name = var.name
}

resource "aws_sns_topic_policy" "billing_alarm_policy" {
  arn    = aws_sns_topic.billing_alarm_topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {

  statement {
    sid    = "AWSBudgetsSNSPublishingPermissions"
    effect = "Allow"

    actions = [
      "SNS:Receive",
      "SNS:Publish"
    ]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.billing_alarm_topic.arn
    ]
  }
}
resource "aws_sns_topic_subscription" "billing_alarm_subscribtion" {
  count = length(var.protocol) > 0 ? length(var.protocol) : 0
  topic_arn = aws_sns_topic.billing_alarm_topic.arn
  protocol  = var.protocol[count.index]
  endpoint = var.opsgenie_endpoints[count.index]
}