resource "aws_cloudwatch_event_rule" "eventtosns" {
  name = "eventtosns"
  event_pattern = jsonencode(
    {
      account = [
        var.account,
      ]
    }
  )
}
resource "aws_cloudwatch_event_target" "eventtosns" {
  arn  = aws_sns_topic.eventtosns.arn
  rule = aws_cloudwatch_event_rule.eventtosns.id
input_transformer {
    input_paths = {
      Source      = "$.source",
      detail-type = "$.detail-type",
      resources   = "$.resources",
      state       = "$.detail.state",
      status      = "$.detail.status"
    }
    input_template = "\"Resource name : <Source> , Action name : <detail-type>, details : <status> <state>, Arn : <resources>\""
  }
}

resource "aws_sns_topic" "eventtosns" {
  name = var.name
}

resource "aws_sns_topic_subscription" "snstoservicedesk" {
  topic_arn = aws_sns_topic.eventtosns.arn
  protocol  = var.protocol
  endpoint  = var.endpoint
}

resource "aws_sns_topic_policy" "eventtosns" {
  arn = aws_sns_topic.eventtosns.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.eventtosns.arn,
    ]

    sid = "__default_statement_ID"
  }
}