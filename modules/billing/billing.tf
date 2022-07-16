resource "aws_budgets_budget" "budget_account" {
  name         = var.budget_settings.name
  budget_type  = var.budget_settings.budget_type
  limit_amount = var.budget_settings.limit_amount
  limit_unit   = var.budget_settings.limit_unit
  time_unit    = var.budget_settings.time_unit
  time_period_end   = var.budget_settings.time_period_end
  time_period_start = var.budget_settings.time_period_start

  notification {
    comparison_operator = var.notification.comparison_operator
    threshold           = var.notification.threshold
    threshold_type      = var.notification.threshold_type
    notification_type   = var.notification.notification_type

    subscriber_sns_topic_arns = [
      aws_sns_topic.alerts-notify-opsgenie[0].arn,
    ]
  }

  depends_on = [
    aws_sns_topic.alerts-notify-email[0],
    aws_sns_topic.alerts-notify-opsgenie[0],
    aws_sns_topic.alerts-notify-sms[0],
  ]
}
