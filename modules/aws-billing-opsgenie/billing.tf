resource "aws_budgets_budget" "budget_account" {
  name         = "${var.account_name} Account Monthly Budget"
  budget_type  = var.budget_type
  limit_amount = var.account_budget_limit
  limit_unit   = var.limit_unit
  time_unit    = var.time_unit

  notification {
    comparison_operator = var.comparison_operator
    threshold           = var.threshold
    threshold_type      = var.threshold_type
    notification_type   = var.notification_type
    subscriber_sns_topic_arns = [
      aws_sns_topic.billing_alarm_topic.arn
    ]
  }

  depends_on = [
    aws_sns_topic.billing_alarm_topic
  ]
}