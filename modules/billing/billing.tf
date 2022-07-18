resource "aws_budgets_budget" "budget_account" {
  name              = var.name
  budget_type       = var.budget_type
  limit_amount      = var.limit_amount
  limit_unit        = var.limit_unit
  time_unit         = var.time_unit
  time_period_end   = var.time_period_end
  time_period_start = var.time_period_start

  notification {
    comparison_operator = var.comparison_operator
    threshold           = var.threshold
    threshold_type      = var.threshold_type
    notification_type   = var.notification_type

    subscriber_sns_topic_arns = [
      aws_sns_topic.alerts_notify_opsgenie[0].arn,
    ]
  }

  depends_on = [
    aws_sns_topic.alerts_notify_email[0],
    aws_sns_topic.alerts_notify_opsgenie[0],
    aws_sns_topic.alerts_notify_sms[0],
  ]
}
