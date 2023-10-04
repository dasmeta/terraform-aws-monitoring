module "topic" {
  source  = "dasmeta/sns/aws//modules/topic"
  version = "1.1.1"

  name            = var.topic_name
  create          = var.create_topic
  delivery_policy = var.delivery_policy

  # email/sms/endpoint(https) subscriptions
  subscriptions = local.subscriptions
}

module "dead_letter_queue" {
  source  = "dasmeta/modules/aws//modules/sqs"
  version = "1.5.1"

  count = var.enable_dead_letter_queue ? 1 : 0

  name            = "${var.topic_name}-dead-letter"
  create_iam_user = false
}

module "fallback-topic" {
  source  = "dasmeta/sns/aws//modules/topic"
  version = "1.1.1"

  name            = "fallback-${var.topic_name}"
  delivery_policy = var.delivery_policy

  # email/sms/endpoint(https) subscriptions
  subscriptions = local.fallback_subscriptions
}
