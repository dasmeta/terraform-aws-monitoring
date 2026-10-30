# Opt-in routing keeps historical findings out of the new destinations and
# tracks Slack and Opsgenie delivery independently per finding.
resource "aws_ssm_parameter" "finding_cutover" {
  count = local.finding_delivery_enabled && nonsensitive(var.finding_delivery.cutover_at == null) ? 1 : 0

  name  = "/${var.name}/finding-delivery-cutover-at"
  type  = "String"
  value = timestamp()

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_dynamodb_table" "finding_delivery" {
  count = local.finding_delivery_enabled ? 1 : 0

  name         = "${var.name}-finding-delivery"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "finding_key"

  attribute {
    name = "finding_key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

module "high_severity_actions" {
  source = "../cloudwatch-alarm-actions"
  count  = local.finding_delivery_enabled ? 1 : 0

  topic_name               = "${var.name}-high-severity-findings"
  create_topic             = true
  web_endpoints            = var.finding_delivery.opsgenie_endpoint == null ? [] : [var.finding_delivery.opsgenie_endpoint]
  enable_dead_letter_queue = true
}

module "security_failure_actions" {
  source = "../cloudwatch-alarm-actions"
  count  = local.finding_delivery_enabled ? 1 : 0

  topic_name   = "${var.name}-delivery-failures-alerts"
  create_topic = true
  slack_webhooks = [for index, webhook in var.alarm_actions.slack_webhooks : merge(webhook, {
    instance_key = "security-delivery-${index}"
  })]
  enable_dead_letter_queue = true
}

data "aws_iam_policy_document" "finding_router" {
  count = local.finding_delivery_enabled ? 1 : 0

  statement {
    sid       = "RecordFindingDelivery"
    actions   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.finding_delivery[0].arn]
  }

  statement {
    sid     = "PublishSecurityFindings"
    actions = ["sns:Publish"]
    resources = [
      module.alarm_actions[0].topic_arn,
      module.high_severity_actions[0].topic_arn,
    ]
  }
}

module "finding_router" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.8.0"
  count   = local.finding_delivery_enabled ? 1 : 0

  function_name = substr("${var.name}-finding-router", 0, 64)
  description   = "Route first delivery of new Security Hub findings to security Slack and high-severity Opsgenie"
  runtime       = "python3.12"
  handler       = "finding_router.lambda_handler"
  source_path   = "${path.module}/functions/finding_router.py"
  timeout       = 30

  environment_variables = {
    DELIVERY_TABLE_NAME = aws_dynamodb_table.finding_delivery[0].name
    FINDING_CUTOVER_AT  = local.finding_cutover_at
    SLACK_TOPIC_ARN     = module.alarm_actions[0].topic_arn
    HIGH_TOPIC_ARN      = module.high_severity_actions[0].topic_arn
    OPSGENIE_API_MODE   = var.finding_delivery.opsgenie_api_key == null ? "false" : "true"
  }

  attach_policy_json        = true
  policy_json               = data.aws_iam_policy_document.finding_router[0].json
  dead_letter_target_arn    = aws_sqs_queue.eventbridge_failed_delivery[0].arn
  attach_dead_letter_policy = true
}

module "opsgenie_api_notifier" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.8.0"
  count   = local.finding_delivery_enabled && nonsensitive(var.finding_delivery.opsgenie_api_key != null) ? 1 : 0

  function_name = substr("${var.name}-opsgenie-api", 0, 64)
  description   = "Create and close per-finding Opsgenie alerts"
  runtime       = "python3.12"
  handler       = "opsgenie_notifier.lambda_handler"
  source_path   = "${path.module}/functions/opsgenie_notifier.py"
  timeout       = 30

  environment_variables = {
    OPSGENIE_API_KEY      = var.finding_delivery.opsgenie_api_key
    OPSGENIE_API_URL      = var.finding_delivery.opsgenie_api_url
    OPSGENIE_ALERT_PREFIX = var.finding_delivery.opsgenie_alert_prefix
  }

  dead_letter_target_arn    = module.high_severity_actions[0].dead_letter_queue_arn
  attach_dead_letter_policy = true
}

resource "aws_lambda_permission" "opsgenie_api_sns" {
  count = length(module.opsgenie_api_notifier)

  statement_id  = "AllowSecurityHubHighSeveritySNS"
  action        = "lambda:InvokeFunction"
  function_name = module.opsgenie_api_notifier[0].lambda_function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.high_severity_actions[0].topic_arn
}

resource "aws_sns_topic_subscription" "opsgenie_api" {
  count = length(module.opsgenie_api_notifier)

  topic_arn = module.high_severity_actions[0].topic_arn
  protocol  = "lambda"
  endpoint  = module.opsgenie_api_notifier[0].lambda_function_arn

  depends_on = [aws_lambda_permission.opsgenie_api_sns]
}

resource "aws_lambda_permission" "finding_router_events" {
  count = local.finding_delivery_enabled ? 1 : 0

  statement_id  = "AllowSecurityHubEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.finding_router[0].lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.automated_alerts.arn
}

# A failed Slack/Lambda or Opsgenie/HTTPS subscription must alert the security
# channel rather than the general account-monitoring topic.
resource "aws_cloudwatch_metric_alarm" "finding_destination_queue_nonempty" {
  for_each = local.finding_delivery_enabled ? {
    slack    = module.alarm_actions[0].dead_letter_queue_name
    opsgenie = module.high_severity_actions[0].dead_letter_queue_name
  } : {}

  alarm_name          = "${var.name}-${each.key}-delivery-dead-letter"
  alarm_description   = "Security Hub ${each.key} delivery failed; ${var.delivery_failure.owner} investigates via ${var.delivery_failure.runbook_url}."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  dimensions          = { QueueName = each.value }
  statistic           = "Maximum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.security_failure_actions[0].topic_arn]
}

# A pre-existing DLQ backlog can keep the queue-depth alarm in ALARM and hide
# later failures. These per-period metrics detect fresh errors without deleting
# historical DLQ evidence. SQS NumberOfMessagesSent is unsuitable for DLQs:
# automatic redrive does not increment it.
resource "aws_cloudwatch_metric_alarm" "finding_destination_new_failure" {
  for_each = local.finding_delivery_enabled ? merge(
    {
      slack-sns = {
        namespace   = "AWS/SNS"
        metric_name = "NumberOfNotificationsFailed"
        dimensions  = { TopicName = split(":", module.alarm_actions[0].topic_arn)[5] }
      }
      opsgenie-sns = {
        namespace   = "AWS/SNS"
        metric_name = "NumberOfNotificationsFailed"
        dimensions  = { TopicName = split(":", module.high_severity_actions[0].topic_arn)[5] }
      }
      router-lambda = {
        namespace   = "AWS/Lambda"
        metric_name = "Errors"
        dimensions  = { FunctionName = module.finding_router[0].lambda_function_name }
      }
    },
    length(module.opsgenie_api_notifier) == 0 ? {} : {
      opsgenie-api-lambda = {
        namespace   = "AWS/Lambda"
        metric_name = "Errors"
        dimensions  = { FunctionName = module.opsgenie_api_notifier[0].lambda_function_name }
      }
    },
    { for key, name in module.alarm_actions[0].slack_lambda_names : "slack-lambda-${key}" => {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      dimensions  = { FunctionName = name }
    } }
  ) : {}

  alarm_name          = substr("${var.name}-${each.key}-new-failures", 0, 255)
  alarm_description   = "New Security Hub ${each.key} delivery failure; ${var.delivery_failure.owner} investigates via ${var.delivery_failure.runbook_url}."
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  dimensions          = each.value.dimensions
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [module.security_failure_actions[0].topic_arn]
}
