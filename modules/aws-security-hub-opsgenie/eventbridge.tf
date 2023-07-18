resource "aws_cloudwatch_event_rule" "securityhub" {
  name        = var.name
  description = "Create EventBridge rule for SecurityHub"

  event_pattern = jsonencode({
    "source" : ["aws.securityhub"],
    "detail-type" : ["Security Hub Findings - Imported"],
    "detail" : {
      "findings" : {
        "RecordState" : ["ACTIVE"],
        "Severity" : {
          "Label" : ["HIGH"]
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.create_teams_target ? 1 : 0

  rule = aws_cloudwatch_event_rule.securityhub.name
  arn  = module.lambda[0].lambda_function_arn
}

resource "aws_cloudwatch_event_target" "slack" {
  count = var.create_slack_target ? 1 : 0

  rule = aws_cloudwatch_event_rule.securityhub.name
  arn  = module.lambda-slack[0].lambda_function_arn
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.create_sns_target ? 1 : 0

  rule = aws_cloudwatch_event_rule.securityhub.name
  arn  = aws_sns_topic.sns-sec[0].arn
}
