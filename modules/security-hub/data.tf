data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# IAM policy document for EventBridge publish permissions only
# This is merged with existing/custom policies to avoid losing any permissions
data "aws_iam_policy_document" "eventbridge_publish_policy" {
  count = var.alarm_actions.enabled && var.alarm_actions.topic_assign_security_hub_policy ? 1 : 0

  # EventBridge publish permissions for automated and manual alert rules
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"
    actions = [
      "SNS:Publish"
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    resources = [
      module.alarm_actions[0].topic_arn
    ]
    condition {
      test     = "ArnEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_cloudwatch_event_rule.automated_alerts.arn,
        aws_cloudwatch_event_rule.manual_alerts[0].arn
      ]
    }
  }
}

# IAM policy document that includes default owner permissions + EventBridge permissions
# Used when no custom policy is provided (var.alarm_actions.policy == null)
# IMPORTANT: aws_sns_topic_policy REPLACES the entire policy, so we must include all permissions
data "aws_iam_policy_document" "sns_topic_policy_merged" {
  count = var.alarm_actions.enabled && var.alarm_actions.topic_assign_security_hub_policy && var.alarm_actions.policy == null ? 1 : 0

  # Default SNS topic owner permissions - allows the account owner to manage the topic
  # This matches AWS's default SNS topic policy
  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      module.alarm_actions[0].topic_arn
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }

  # Include EventBridge publish permissions
  source_policy_documents = [
    data.aws_iam_policy_document.eventbridge_publish_policy[0].json
  ]
}

# IAM policy document that merges custom policy with EventBridge permissions
# Used when a custom policy is provided (var.alarm_actions.policy != null)
# IMPORTANT: aws_sns_topic_policy REPLACES the entire policy, so we merge custom + EventBridge
# Note: We merge custom policy with EventBridge policy only (not the merged policy which includes default owner permissions)
# This ensures the custom policy's owner permissions are preserved
data "aws_iam_policy_document" "sns_topic_policy_custom_merged" {
  count = var.alarm_actions.enabled && var.alarm_actions.topic_assign_security_hub_policy && var.alarm_actions.policy != null ? 1 : 0

  # Include both custom policy and EventBridge publish permissions
  source_policy_documents = [
    jsonencode(var.alarm_actions.policy),
    data.aws_iam_policy_document.eventbridge_publish_policy[0].json
  ]
}
